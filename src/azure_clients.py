# -*- coding: utf-8 -*-
"""
Module for initializing and providing clients for various Azure services.
It utilizes Managed Identity (via Azure Identity) to authenticate and
retrieves secrets (like keys and endpoints) from Azure Key Vault.
"""

import os
import logging
from azure.identity import ManagedIdentityCredential, DefaultAzureCredential, ChainedTokenCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import ResourceNotFoundError, ClientAuthenticationError
from azure.core.credentials import AzureKeyCredential # For Search and some AI Services
from azure.cosmos import CosmosClient
from azure.storage.blob import BlobServiceClient
from azure.search.documents import SearchClient
from azure.ai.textanalytics import TextAnalyticsClient # For Language
from azure.ai.vision.imageanalysis import ImageAnalysisClient # For Vision
from azure.ai.documentintelligence import DocumentIntelligenceClient # For Document Intelligence
from azure.cognitiveservices.speech import SpeechConfig # For Speech (uses key directly)
from openai import AzureOpenAI # Using the 'openai' package configured for Azure
from typing import Dict, Optional, List, Union

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# to reduce verbosity of Azure SDK logs
logging.getLogger("azure.core.pipeline.policies.http_logging_policy").setLevel(logging.WARNING)

# --- Global Variables ---
# List of secret names expected to be in Key Vault
# These should match the names you used when adding secrets to Key Vault
EXPECTED_SECRET_NAMES = [
    "AIServicesKey",
    "AIServicesEndpoint",
    "AzureOpenAIKey",
    "AzureOpenAIEndpoint",
    "CosmosDBEndpoint",
    "CosmosDBKey",
    "StorageAccountName",
    "StorageAccountKey", # Or "StorageConnectionString"
    "SearchServiceEndpoint",
    "SearchAdminKey"
]

# --- Credential Initialization (Centralized) ---
# Use Chained Credential for flexibility (Managed Identity in Azure, DefaultAzureCredential locally)
# Ensure AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET are set for DefaultAzureCredential
# if using Service Principal locally, or be logged in via Azure CLI.
try:
    AZURE_CREDENTIAL = ChainedTokenCredential(ManagedIdentityCredential(), DefaultAzureCredential())
    logger.info("Azure credential initialized using ChainedTokenCredential.")
except Exception as e:
    logger.error(f"Failed to initialize Azure credential: {e}", exc_info=True)
    AZURE_CREDENTIAL = None # Indicate failure

# --- Key Vault Client Initialization ---

def get_key_vault_client() -> Optional[SecretClient]:
    """
    Initializes and returns an Azure Key Vault SecretClient using the shared AZURE_CREDENTIAL.
    Reads the Key Vault URI from the AZURE_KEY_VAULT_URI environment variable.

    Returns:
        SecretClient or None if initialization fails.
    """
    key_vault_uri = os.getenv("AZURE_KEY_VAULT_URI")
    if not key_vault_uri:
        logger.error("Azure Key Vault URI not found. Set the AZURE_KEY_VAULT_URI environment variable.")
        return None
    if not AZURE_CREDENTIAL:
        logger.error("Azure credential is not available. Cannot create Key Vault client.")
        return None

    try:
        logger.info(f"Attempting to create SecretClient for Key Vault: {key_vault_uri}")
        kv_client = SecretClient(vault_url=key_vault_uri, credential=AZURE_CREDENTIAL)
        # Perform a simple test call to verify connection and permissions
        # This helps catch issues early (e.g., wrong URI, missing permissions)
        kv_client.list_properties_of_secrets(max_results=1)
        logger.info("SecretClient created and verified successfully.")
        return kv_client
    except ClientAuthenticationError as auth_error:
        logger.error(f"Authentication failed for Key Vault '{key_vault_uri}': {auth_error}", exc_info=True)
        if "ManagedIdentityCredential" in str(auth_error):
             logger.error("Ensure Managed Identity is enabled and has 'Get Secrets' permission on the Key Vault.")
        return None
    except Exception as e:
        # Catch other potential errors like DNS issues, network problems, etc.
        logger.error(f"An unexpected error occurred while creating/verifying SecretClient for Key Vault '{key_vault_uri}': {e}", exc_info=True)
        return None

# --- Function to Retrieve Secrets ---

def get_secrets_from_key_vault(secret_names: List[str] = EXPECTED_SECRET_NAMES) -> Optional[Dict[str, Optional[str]]]:
    """
    Retrieves a dictionary of specified secrets from Azure Key Vault.

    Args:
        secret_names (List[str]): A list of secret names to retrieve.

    Returns:
        Optional[Dict[str, Optional[str]]]: Dictionary with secret names as keys.
                                            Values are secret values or None if not found/error.
                                            Returns None if the KV client fails to initialize.
    """
    kv_client = get_key_vault_client()
    if not kv_client:
        logger.error("Failed to initialize Key Vault client. Cannot retrieve secrets.")
        return None

    retrieved_secrets: Dict[str, Optional[str]] = {name: None for name in secret_names} # Initialize with None
    logger.info(f"Retrieving secrets from Key Vault: {', '.join(secret_names)}")
    retrieved_count = 0

    for secret_name in secret_names:
        try:
            logger.debug(f"Attempting to retrieve secret: {secret_name}")
            secret_bundle = kv_client.get_secret(secret_name)
            retrieved_secrets[secret_name] = secret_bundle.value
            retrieved_count += 1
            logger.debug(f"Successfully retrieved secret: {secret_name}")
        except ResourceNotFoundError:
            logger.warning(f"Secret '{secret_name}' not found in Key Vault '{kv_client.vault_url}'. Will be None.")
            # Continue retrieving other secrets
        except ClientAuthenticationError as auth_error:
            # If we fail auth while getting a specific secret, it's likely a permission issue
            # for that secret or the identity. Stop the process.
            logger.error(f"Authentication error retrieving secret '{secret_name}': {auth_error}. Stopping secret retrieval.", exc_info=True)
            return None # Treat auth errors during retrieval as fatal
        except Exception as e:
            logger.error(f"Unexpected error retrieving secret '{secret_name}': {e}. Skipping this secret.", exc_info=True)
            # Continue retrieving other secrets

    logger.info(f"Finished retrieving secrets. Got values for {retrieved_count}/{len(secret_names)} secrets.")
    return retrieved_secrets

# --- Initialization Functions for Service Clients ---
# These functions use the retrieved secrets dictionary.

def get_cosmos_client(secrets: Dict[str, Optional[str]]) -> Optional[CosmosClient]:
    """Initializes and returns an Azure Cosmos DB client."""
    endpoint = secrets.get("CosmosDBEndpoint")
    key = secrets.get("CosmosDBKey")

    if not endpoint:
        logger.error("Cosmos DB endpoint (CosmosDBEndpoint) not found in retrieved secrets.")
        return None
    if not key:
         logger.error("Cosmos DB key (CosmosDBKey) not found in retrieved secrets.")
         # Note: Direct Managed Identity auth for data plane might require specific roles
         # and SDK handling not implemented here for simplicity. Key is assumed for now.
         return None

    try:
        logger.info(f"Initializing Cosmos DB Client for endpoint: {endpoint}")
        client = CosmosClient(url=endpoint, credential=key)
        # Test connection by listing databases
        list(client.list_databases())
        logger.info("Cosmos DB Client initialized and verified successfully.")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize or verify Cosmos DB client: {e}", exc_info=True)
        return None

def get_openai_client(secrets: Dict[str, Optional[str]]) -> Optional[AzureOpenAI]:
     """Initializes and returns an Azure OpenAI client using the 'openai' library."""
     endpoint = secrets.get("AzureOpenAIEndpoint")
     api_key = secrets.get("AzureOpenAIKey")
     # Get API version from env var or use a sensible default
     api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview")

     if not endpoint:
         logger.error("Azure OpenAI endpoint (AzureOpenAIEndpoint) not found in retrieved secrets.")
         return None

     credential_to_use = None
     auth_method = "API Key"
     if not api_key:
         logger.warning("Azure OpenAI key (AzureOpenAIKey) not found. Attempting to use Azure Credentials (Managed Identity/Default).")
         if AZURE_CREDENTIAL:
             credential_to_use = AZURE_CREDENTIAL
             auth_method = "Azure AD/Managed Identity"
         else:
             logger.error("Azure OpenAI key is missing and Azure Credential is not available.")
             return None
     # else: key is present, will be used if credential_to_use remains None

     try:
         logger.info(f"Initializing Azure OpenAI Client for endpoint: {endpoint} using API version {api_version} and auth: {auth_method}")
         if credential_to_use:
              # Use token provider for AAD/Managed Identity
              client = AzureOpenAI(
                  azure_endpoint=endpoint,
                  api_version=api_version,
                  azure_ad_token_provider=credential_to_use
              )
         else:
              # Use API key
              client = AzureOpenAI(
                  azure_endpoint=endpoint,
                  api_version=api_version,
                  api_key=api_key
              )

         # Perform a simple test (e.g., list models) - requires appropriate role assignment
         try:
            client.models.list()
            logger.info("Azure OpenAI Client initialized and verified successfully.")
         except Exception as test_error:
             logger.warning(f"Azure OpenAI Client initialized, but test call (list models) failed: {test_error}. Check permissions/endpoint.")
             # Continue, client might still work for other operations

         return client
     except Exception as e:
         logger.error(f"Failed to initialize Azure OpenAI client: {e}", exc_info=True)
         return None

def get_ai_services_credential(secrets: Dict[str, Optional[str]]) -> Optional[AzureKeyCredential]:
     """Creates an AzureKeyCredential for AI Services using the unified key."""
     key = secrets.get("AIServicesKey")
     if not key:
         logger.error("AI Services key (AIServicesKey) not found in retrieved secrets.")
         return None
     logger.info("AI Services AzureKeyCredential created.")
     return AzureKeyCredential(key)

def get_language_client(secrets: Dict[str, Optional[str]]) -> Optional[TextAnalyticsClient]:
    """Initializes and returns an Azure AI Language (Text Analytics) client."""
    endpoint = secrets.get("AIServicesEndpoint")
    credential = get_ai_services_credential(secrets) # Use unified key credential

    if not endpoint or not credential:
        logger.error("AI Services endpoint or credential not available for Language client.")
        return None
    try:
        logger.info(f"Initializing Text Analytics Client for endpoint: {endpoint}")
        client = TextAnalyticsClient(endpoint=endpoint, credential=credential)
        # Test connection (optional, requires specific permissions)
        # client.detect_language(documents=["test"])
        logger.info("Text Analytics Client initialized successfully.")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize Text Analytics client: {e}", exc_info=True)
        return None

def get_vision_client(secrets: Dict[str, Optional[str]]) -> Optional[ImageAnalysisClient]:
    """Initializes and returns an Azure AI Vision (Image Analysis) client."""
    endpoint = secrets.get("AIServicesEndpoint")
    credential = get_ai_services_credential(secrets) # Use unified key credential

    if not endpoint or not credential:
        logger.error("AI Services endpoint or credential not available for Vision client.")
        return None
    try:
        logger.info(f"Initializing Image Analysis Client for endpoint: {endpoint}")
        client = ImageAnalysisClient(endpoint=endpoint, credential=credential)
        # Test connection (optional, requires specific permissions, maybe analyze a dummy URL?)
        logger.info("Image Analysis Client initialized successfully.")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize Image Analysis client: {e}", exc_info=True)
        return None

def get_doc_intelligence_client(secrets: Dict[str, Optional[str]]) -> Optional[DocumentIntelligenceClient]:
    """Initializes and returns an Azure AI Document Intelligence client."""
    endpoint = secrets.get("AIServicesEndpoint")
    credential = get_ai_services_credential(secrets) # Use unified key credential

    if not endpoint or not credential:
        logger.error("AI Services endpoint or credential not available for Document Intelligence client.")
        return None
    try:
        logger.info(f"Initializing Document Intelligence Client for endpoint: {endpoint}")
        client = DocumentIntelligenceClient(endpoint=endpoint, credential=credential)
        # Test connection (optional, e.g., get resource details)
        # client.get_resource_details()
        logger.info("Document Intelligence Client initialized successfully.")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize Document Intelligence client: {e}", exc_info=True)
        return None

def get_speech_config(secrets: Dict[str, Optional[str]]) -> Optional[SpeechConfig]:
    """Initializes and returns an Azure AI Speech configuration object."""
    key = secrets.get("AIServicesKey")
    endpoint = secrets.get("AIServicesEndpoint")
    region = None
    if endpoint:
        try:
            # Attempt to parse region (e.g., https://westeurope.api.cognitive.microsoft.com/)
            # More robust parsing needed if endpoint formats vary significantly
            match = re.search(r"https://(\w+)\.api\.cognitive\.microsoft\.com", endpoint)
            if match:
                region = match.group(1)
            else:
                 logger.warning(f"Could not parse region from AI Services endpoint format: {endpoint}")
        except Exception as parse_error:
            logger.warning(f"Error parsing region from AI Services endpoint '{endpoint}': {parse_error}")

    if not key:
        logger.error("AI Services key (AIServicesKey) not found for Speech config.")
        return None
    if not region:
        logger.error("Region could not be determined for Speech config. Consider adding a 'SpeechRegion' secret.")
        return None

    try:
        logger.info(f"Initializing Speech Config for region: {region}")
        speech_config = SpeechConfig(subscription=key, region=region)
        logger.info("Speech Config initialized successfully.")
        return speech_config
    except Exception as e:
        logger.error(f"Failed to initialize Speech Config: {e}", exc_info=True)
        return None

def get_search_client(secrets: Dict[str, Optional[str]], index_name: str) -> Optional[SearchClient]:
     """Initializes and returns an Azure AI Search client for a specific index."""
     endpoint = secrets.get("SearchServiceEndpoint")
     key = secrets.get("SearchAdminKey") # Use Admin key for broader testing/management

     if not endpoint:
         logger.error("Search service endpoint (SearchServiceEndpoint) not found in retrieved secrets.")
         return None
     if not key:
         logger.error("Search admin key (SearchAdminKey) not found in retrieved secrets.")
         return None
     if not index_name:
         logger.error("Search index name is required to create a SearchClient.")
         return None

     try:
         credential = AzureKeyCredential(key)
         logger.info(f"Initializing Search Client for endpoint: {endpoint}, index: {index_name}")
         client = SearchClient(endpoint=endpoint, index_name=index_name, credential=credential)
         # Test connection (optional, e.g., get document count)
         # client.get_document_count()
         logger.info("Search Client initialized successfully.")
         return client
     except Exception as e:
         logger.error(f"Failed to initialize Search client: {e}", exc_info=True)
         return None

def get_blob_service_client(secrets: Dict[str, Optional[str]]) -> Optional[BlobServiceClient]:
     """Initializes and returns an Azure Blob Storage client."""
     account_name = secrets.get("StorageAccountName")
     account_key = secrets.get("StorageAccountKey")
     connection_string = secrets.get("StorageConnectionString") # Allow connection string as alternative

     credential_to_use: Union[str, ManagedIdentityCredential, DefaultAzureCredential, None] = None
     auth_method = "Unknown"

     if connection_string:
         logger.info("Using Connection String for Blob Storage authentication.")
         auth_method = "Connection String"
     elif account_name and account_key:
         logger.info("Using Account Key for Blob Storage authentication.")
         # Construct connection string if key is provided but connection string isn't
         connection_string = f"DefaultEndpointsProtocol=https;AccountName={account_name};AccountKey={account_key};EndpointSuffix=core.windows.net"
         auth_method = "Account Key (via constructed CS)"
     elif account_name and AZURE_CREDENTIAL:
         logger.warning("Storage account key/connection string not found. Attempting to use Azure Credentials (Managed Identity/Default) for Blob Storage.")
         credential_to_use = AZURE_CREDENTIAL
         auth_method = "Azure AD/Managed Identity"
     elif not account_name:
          logger.error("Storage account name (StorageAccountName) not found in retrieved secrets.")
          return None
     else: # account_name exists but no key/CS and no AZURE_CREDENTIAL
         logger.error("No valid credential (Key, Connection String, or Managed Identity) found for Blob Storage.")
         return None

     try:
         account_url = f"https://{account_name}.blob.core.windows.net" if account_name else None
         logger.info(f"Initializing Blob Service Client for account: {account_name} using {auth_method}")
         if connection_string:
              blob_service_client = BlobServiceClient.from_connection_string(connection_string)
         elif account_url and credential_to_use:
              blob_service_client = BlobServiceClient(account_url=account_url, credential=credential_to_use)
         else:
              # This case should ideally not be reached due to prior checks
              logger.error("Logic error: Could not determine Blob Storage client initialization method.")
              return None

         # Test connection
         blob_service_client.get_service_properties()
         logger.info("Blob Service Client initialized and verified successfully.")
         return blob_service_client
     except Exception as e:
         logger.error(f"Failed to initialize or verify Blob Service client: {e}", exc_info=True)
         return None


# --- Main Execution (Example Usage/Test) ---
# This block helps test client initialization when running the script directly.
if __name__ == "__main__":
    print("--- Testing Azure Client Initialization ---")

    # Load .env file for local testing if it exists
    try:
        from dotenv import load_dotenv
        if load_dotenv():
             print("Loaded environment variables from .env file.")
        else:
             print("No .env file found or it is empty.")
    except ImportError:
        print("dotenv library not found, skipping .env load. Ensure environment variables are set.")

    # 1. Retrieve Secrets
    print("\n[1] Retrieving Secrets from Key Vault...")
    secrets = get_secrets_from_key_vault()

    if secrets:
        print("   Secrets retrieved (values partially masked):")
        for name, value_part in secrets.items():
            if value_part:
                 print(f"     - {name}: {value_part[:4]}...{value_part[-4:]}" if len(value_part) > 8 else f"     - {name}: Present")
            else:
                 print(f"     - {name}: Not Found/Empty")

        # 2. Initialize Clients (using retrieved secrets)
        print("\n[2] Initializing Azure Service Clients...")

        cosmos_client = get_cosmos_client(secrets)
        print(f"   - Cosmos DB Client: {'OK' if cosmos_client else 'FAILED'}")

        openai_client = get_openai_client(secrets)
        print(f"   - Azure OpenAI Client: {'OK' if openai_client else 'FAILED'}")

        language_client = get_language_client(secrets)
        print(f"   - Language Client: {'OK' if language_client else 'FAILED'}")

        vision_client = get_vision_client(secrets)
        print(f"   - Vision Client: {'OK' if vision_client else 'FAILED'}")

        doc_intel_client = get_doc_intelligence_client(secrets)
        print(f"   - Document Intelligence Client: {'OK' if doc_intel_client else 'FAILED'}")

        speech_config = get_speech_config(secrets)
        print(f"   - Speech Config: {'OK' if speech_config else 'FAILED'}")

        # Replace 'your-recipe-index' with an actual index name for testing Search
        # Get index name from env var or use a default for testing
        test_index_name = os.getenv("SEARCH_INDEX_NAME", "test-index-placeholder")
        search_client = get_search_client(secrets, index_name=test_index_name)
        print(f"   - Search Client (index: {test_index_name}): {'OK' if search_client else 'FAILED'}")

        blob_client = get_blob_service_client(secrets)
        print(f"   - Blob Service Client: {'OK' if blob_client else 'FAILED'}")

    else:
        print("\n[!] Failed to retrieve secrets from Key Vault. Cannot initialize clients.")

    print("\n--- Test Complete ---")

