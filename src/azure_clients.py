# -*- coding: utf-8 -*-
"""
Module for initializing and providing clients for various Azure services.
It utilizes Managed Identity (via Azure Identity) to authenticate and
retrieves secrets (like keys and endpoints) from Azure Key Vault.
Includes function to initialize and store clients in Streamlit session state.
"""

import os
import logging
import streamlit as st # Added for session state
from azure.identity import ManagedIdentityCredential, DefaultAzureCredential, ChainedTokenCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import ResourceNotFoundError, ClientAuthenticationError
from azure.core.credentials import AzureKeyCredential
from azure.cosmos import CosmosClient, DatabaseProxy, ContainerProxy # Added Proxies
from azure.storage.blob import BlobServiceClient
from azure.search.documents import SearchClient
from azure.ai.textanalytics import TextAnalyticsClient
from azure.ai.vision.imageanalysis import ImageAnalysisClient
from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.cognitiveservices.speech import SpeechConfig
from openai import AzureOpenAI
from typing import Dict, Optional, List, Union, Tuple # Added Tuple
import re # For parsing region from endpoint

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Reduce verbosity of Azure SDK HTTP logging
logging.getLogger("azure.core.pipeline.policies.http_logging_policy").setLevel(logging.WARNING)
logging.getLogger("azure.identity._internal.managed_identity_client").setLevel(logging.WARNING) # Also often verbose

# --- Global Variables ---
EXPECTED_SECRET_NAMES = [
    "AIServicesKey", "AIServicesEndpoint", "AzureOpenAIKey", "AzureOpenAIEndpoint",
    "CosmosDBEndpoint", "CosmosDBKey", "StorageAccountName", "StorageAccountKey", # Or StorageConnectionString
    "SearchServiceEndpoint", "SearchAdminKey"
]
# Define keys for session state storage
SESSION_STATE_SECRETS = 'azure_secrets'
SESSION_STATE_COSMOS_CLIENT = 'cosmos_client'
SESSION_STATE_RECIPE_CONTAINER = 'recipe_container'
SESSION_STATE_PANTRY_CONTAINER = 'pantry_container'
SESSION_STATE_INGREDIENT_CONTAINER = 'ingredient_container'
SESSION_STATE_OPENAI_CLIENT = 'openai_client'
SESSION_STATE_LANGUAGE_CLIENT = 'language_client'
SESSION_STATE_VISION_CLIENT = 'vision_client'
SESSION_STATE_DOC_INTEL_CLIENT = 'doc_intel_client'
SESSION_STATE_SPEECH_CONFIG = 'speech_config'
SESSION_STATE_SEARCH_CLIENT = 'search_client' # Note: Search client is index-specific
SESSION_STATE_BLOB_CLIENT = 'blob_client'
SESSION_STATE_CLIENTS_INITIALIZED = 'azure_clients_initialized'


# --- Credential Initialization (Centralized) ---
try:
    # Use Chained Credential for flexibility: Try Managed Identity first, then fall back to DefaultAzureCredential
    AZURE_CREDENTIAL = ChainedTokenCredential(ManagedIdentityCredential(), DefaultAzureCredential())
    logger.info("Azure credential initialized using ChainedTokenCredential.")
except Exception as e:
    logger.error(f"Failed to initialize Azure credential: {e}", exc_info=True)
    AZURE_CREDENTIAL = None

# --- Key Vault Client Initialization ---
# Renamed with underscore as it's now primarily internal
def _get_key_vault_client() -> Optional[SecretClient]:
    """Internal function to initialize Key Vault client."""
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
        # Perform a simple test call to verify connection and permissions using list_properties_of_secrets
        logger.debug("Verifying Key Vault connection by listing secret properties (max 1)...")
        list(kv_client.list_properties_of_secrets()) # Corrected method call
        logger.info("SecretClient created and verified successfully.")
        return kv_client
    except ClientAuthenticationError as auth_error:
        logger.error(f"Authentication failed for Key Vault '{key_vault_uri}': {auth_error}", exc_info=True)
        if "ManagedIdentityCredential" in str(auth_error):
             logger.error("Ensure Managed Identity is enabled and has 'Get Secrets' permission on the Key Vault.")
        return None
    except Exception as e:
        logger.error(f"An unexpected error occurred while creating/verifying SecretClient for Key Vault '{key_vault_uri}': {e}", exc_info=True)
        return None

# --- Function to Retrieve Secrets ---
# Renamed with underscore
def _get_secrets_from_key_vault(kv_client: SecretClient, secret_names: List[str] = EXPECTED_SECRET_NAMES) -> Optional[Dict[str, Optional[str]]]:
    """Internal function to retrieve secrets using an existing KV client."""
    retrieved_secrets: Dict[str, Optional[str]] = {name: None for name in secret_names}
    logger.info(f"Retrieving secrets from Key Vault: {', '.join(secret_names)}")
    retrieved_count = 0
    for secret_name in secret_names:
        try:
            secret_bundle = kv_client.get_secret(secret_name)
            retrieved_secrets[secret_name] = secret_bundle.value
            retrieved_count += 1
        except ResourceNotFoundError:
            logger.warning(f"Secret '{secret_name}' not found in Key Vault '{kv_client.vault_url}'. Will be None.")
        except ClientAuthenticationError as auth_error:
            logger.error(f"Authentication error retrieving secret '{secret_name}': {auth_error}. Stopping secret retrieval.", exc_info=True)
            return None # Treat auth errors during retrieval as fatal
        except Exception as e:
            logger.error(f"Unexpected error retrieving secret '{secret_name}': {e}. Skipping this secret.", exc_info=True)
    logger.info(f"Finished retrieving secrets. Got values for {retrieved_count}/{len(secret_names)} secrets.")
    return retrieved_secrets


# --- Initialization Functions for Service Clients (Now Internal Helpers) ---
# These functions now take the secrets dict as input and return the client

def _initialize_cosmos_client(secrets: Dict[str, Optional[str]]) -> Optional[CosmosClient]:
    """Initializes and returns an Azure Cosmos DB client."""
    endpoint = secrets.get("CosmosDBEndpoint")
    key = secrets.get("CosmosDBKey")
    if not endpoint or not key:
        logger.error("Cosmos DB endpoint or key not found for client initialization.")
        return None
    try:
        logger.info(f"Initializing Cosmos DB Client for endpoint: {endpoint}")
        client = CosmosClient(url=endpoint, credential=key)
        list(client.list_databases()) # Test connection
        logger.info("Cosmos DB Client initialized and verified successfully.")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize or verify Cosmos DB client: {e}", exc_info=True)
        return None

def _initialize_openai_client(secrets: Dict[str, Optional[str]]) -> Optional[AzureOpenAI]:
     """Initializes and returns an Azure OpenAI client using the 'openai' library."""
     endpoint = secrets.get("AzureOpenAIEndpoint")
     api_key = secrets.get("AzureOpenAIKey")
     api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview")
     if not endpoint:
         logger.error("Azure OpenAI endpoint not found for client initialization.")
         return None
     credential_to_use = None
     auth_method = "API Key"
     if not api_key:
         logger.warning("Azure OpenAI key not found. Attempting Azure Credentials.")
         if AZURE_CREDENTIAL:
             credential_to_use = AZURE_CREDENTIAL
             auth_method = "Azure AD/Managed Identity"
         else:
             logger.error("Azure OpenAI key missing and Azure Credential unavailable.")
             return None
     try:
         logger.info(f"Initializing Azure OpenAI Client (endpoint: {endpoint}, auth: {auth_method})")
         if credential_to_use:
              client = AzureOpenAI(azure_endpoint=endpoint, api_version=api_version, azure_ad_token_provider=credential_to_use)
         else:
              client = AzureOpenAI(azure_endpoint=endpoint, api_version=api_version, api_key=api_key)
         # Test connection (requires appropriate role like Cognitive Services OpenAI User)
         try:
            client.models.list()
            logger.info("Azure OpenAI Client initialized and verified successfully.")
         except Exception as test_error:
             logger.warning(f"Azure OpenAI Client initialized, but test call (list models) failed: {test_error}. Check permissions/endpoint.")
         return client
     except Exception as e:
         logger.error(f"Failed to initialize Azure OpenAI client: {e}", exc_info=True)
         return None

def _get_ai_services_credential(secrets: Dict[str, Optional[str]]) -> Optional[AzureKeyCredential]:
     """Creates an AzureKeyCredential for AI Services using the unified key."""
     key = secrets.get("AIServicesKey")
     if not key:
         logger.error("AI Services key (AIServicesKey) not found.")
         return None
     return AzureKeyCredential(key)

def _initialize_language_client(secrets: Dict[str, Optional[str]]) -> Optional[TextAnalyticsClient]:
    """Initializes and returns an Azure AI Language (Text Analytics) client."""
    endpoint = secrets.get("AIServicesEndpoint")
    credential = _get_ai_services_credential(secrets)
    if not endpoint or not credential:
        logger.error("AI Services endpoint or credential not available for Language client.")
        return None
    try:
        logger.info(f"Initializing Text Analytics Client for endpoint: {endpoint}")
        client = TextAnalyticsClient(endpoint=endpoint, credential=credential)
        logger.info("Text Analytics Client initialized successfully.")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize Text Analytics client: {e}", exc_info=True)
        return None

def _initialize_vision_client(secrets: Dict[str, Optional[str]]) -> Optional[ImageAnalysisClient]:
    """Initializes and returns an Azure AI Vision (Image Analysis) client."""
    endpoint = secrets.get("AIServicesEndpoint")
    credential = _get_ai_services_credential(secrets)
    if not endpoint or not credential:
        logger.error("AI Services endpoint or credential not available for Vision client.")
        return None
    try:
        logger.info(f"Initializing Image Analysis Client for endpoint: {endpoint}")
        client = ImageAnalysisClient(endpoint=endpoint, credential=credential)
        logger.info("Image Analysis Client initialized successfully.")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize Image Analysis client: {e}", exc_info=True)
        return None

def _initialize_doc_intelligence_client(secrets: Dict[str, Optional[str]]) -> Optional[DocumentIntelligenceClient]:
    """Initializes and returns an Azure AI Document Intelligence client."""
    endpoint = secrets.get("AIServicesEndpoint")
    credential = _get_ai_services_credential(secrets)
    if not endpoint or not credential:
        logger.error("AI Services endpoint or credential not available for Doc Intelligence client.")
        return None
    try:
        logger.info(f"Initializing Document Intelligence Client for endpoint: {endpoint}")
        client = DocumentIntelligenceClient(endpoint=endpoint, credential=credential)
        logger.info("Document Intelligence Client initialized successfully.")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize Document Intelligence client: {e}", exc_info=True)
        return None

def _initialize_speech_config(secrets: Dict[str, Optional[str]]) -> Optional[SpeechConfig]:
    """Initializes and returns an Azure AI Speech configuration object."""
    key = secrets.get("AIServicesKey")
    endpoint = secrets.get("AIServicesEndpoint")
    region = None
    if endpoint:
        try:
            # Attempt to parse region from standard endpoint format
            match = re.search(r"https://([\w-]+)\.api\.cognitive\.microsoft\.com", endpoint)
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
        logger.error("Region could not be determined for Speech config. Consider adding a 'SpeechRegion' secret to Key Vault.")
        return None

    try:
        logger.info(f"Initializing Speech Config for region: {region}")
        speech_config = SpeechConfig(subscription=key, region=region)
        logger.info("Speech Config initialized successfully.")
        return speech_config
    except Exception as e:
        logger.error(f"Failed to initialize Speech Config: {e}", exc_info=True)
        return None

def _initialize_search_client(secrets: Dict[str, Optional[str]], index_name: str) -> Optional[SearchClient]:
     """Initializes and returns an Azure AI Search client for a specific index."""
     endpoint = secrets.get("SearchServiceEndpoint")
     key = secrets.get("SearchAdminKey") # Using Admin key for flexibility during dev/test
     if not endpoint:
         logger.error("Search service endpoint (SearchServiceEndpoint) not found.")
         return None
     if not key:
         logger.error("Search admin key (SearchAdminKey) not found.")
         return None
     if not index_name:
         logger.error("Search index name required.")
         return None
     try:
         credential = AzureKeyCredential(key)
         logger.info(f"Initializing Search Client for endpoint: {endpoint}, index: {index_name}")
         client = SearchClient(endpoint=endpoint, index_name=index_name, credential=credential)
         # Test connection by getting index stats (requires admin key)
         client.get_document_count()
         logger.info("Search Client initialized and verified successfully.")
         return client
     except Exception as e:
         logger.error(f"Failed to initialize or verify Search client: {e}", exc_info=True)
         return None

def _initialize_blob_service_client(secrets: Dict[str, Optional[str]]) -> Optional[BlobServiceClient]:
     """Initializes and returns an Azure Blob Storage client."""
     account_name = secrets.get("StorageAccountName")
     account_key = secrets.get("StorageAccountKey")
     connection_string = secrets.get("StorageConnectionString") # Allow explicit connection string
     credential_to_use: Union[str, ManagedIdentityCredential, DefaultAzureCredential, None] = None
     auth_method = "Unknown"

     if connection_string:
         auth_method = "Connection String"
     elif account_name and account_key:
         # Construct connection string if key is provided but connection string isn't
         connection_string = f"DefaultEndpointsProtocol=https;AccountName={account_name};AccountKey={account_key};EndpointSuffix=core.windows.net"
         auth_method = "Account Key (via constructed CS)"
     elif account_name and AZURE_CREDENTIAL:
         credential_to_use = AZURE_CREDENTIAL
         auth_method = "Azure AD/Managed Identity"
     elif not account_name:
          logger.error("Storage account name (StorageAccountName) not found.")
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
              logger.error("Logic error: Could not determine Blob Storage client initialization method.")
              return None

         # Test connection
         blob_service_client.get_service_properties()
         logger.info("Blob Service Client initialized and verified successfully.")
         return blob_service_client
     except Exception as e:
         logger.error(f"Failed to initialize or verify Blob Service client: {e}", exc_info=True)
         return None


# --- Main Initialization Function for Streamlit App ---

def initialize_clients_in_session_state(force_reload: bool = False):
    """
    Initializes all necessary Azure clients and stores them in st.session_state.
    Checks session state first to avoid re-initialization unless force_reload is True.
    """
    # Use a more specific key to avoid potential clashes
    session_key = f"{__name__}_clients_initialized"

    if not force_reload and st.session_state.get(session_key):
        # logger.debug("Azure clients already initialized in session state.")
        return True # Already initialized

    logger.info(f"Initializing Azure clients (force_reload={force_reload})...")
    st.session_state[session_key] = False # Mark as initializing

    # 1. Get Secrets
    kv_client = _get_key_vault_client()
    if not kv_client:
        st.error("Fatal: Could not initialize Key Vault client.")
        return False
    secrets = _get_secrets_from_key_vault(kv_client)
    if secrets is None: # Check for None explicitly (indicates failure during retrieval)
        st.error("Fatal: Failed to retrieve secrets from Key Vault.")
        return False
    st.session_state[SESSION_STATE_SECRETS] = secrets
    logger.info("Secrets loaded into session state.")

    # 2. Initialize and Store Clients
    init_success = True # Assume success initially

    # Cosmos DB Client and Containers
    cosmos_client = _initialize_cosmos_client(secrets)
    st.session_state[SESSION_STATE_COSMOS_CLIENT] = cosmos_client
    if cosmos_client:
        db_name = os.getenv("COSMOS_DATABASE_NAME", "MiraiCookDB")
        recipe_container_name = os.getenv("RECIPE_CONTAINER_NAME", "Recipes")
        pantry_container_name = os.getenv("PANTRY_CONTAINER_NAME", "Pantry")
        ingredient_container_name = os.getenv("INGREDIENT_CONTAINER_NAME", "IngredientsMasterList")
        try:
            db_client = cosmos_client.get_database_client(db_name)
            st.session_state[SESSION_STATE_RECIPE_CONTAINER] = db_client.get_container_client(recipe_container_name)
            st.session_state[SESSION_STATE_PANTRY_CONTAINER] = db_client.get_container_client(pantry_container_name)
            st.session_state[SESSION_STATE_INGREDIENT_CONTAINER] = db_client.get_container_client(ingredient_container_name)
            logger.info("Cosmos DB container clients stored in session state.")
        except Exception as e:
            logger.error(f"Failed to get Cosmos DB container clients: {e}", exc_info=True)
            init_success = False
    else:
        init_success = False # Cosmos client init failed

    # Initialize other clients and store them, updating init_success if any fail
    st.session_state[SESSION_STATE_OPENAI_CLIENT] = _initialize_openai_client(secrets)
    if not st.session_state[SESSION_STATE_OPENAI_CLIENT]: init_success = False

    st.session_state[SESSION_STATE_LANGUAGE_CLIENT] = _initialize_language_client(secrets)
    if not st.session_state[SESSION_STATE_LANGUAGE_CLIENT]: init_success = False

    st.session_state[SESSION_STATE_VISION_CLIENT] = _initialize_vision_client(secrets)
    if not st.session_state[SESSION_STATE_VISION_CLIENT]: init_success = False

    st.session_state[SESSION_STATE_DOC_INTEL_CLIENT] = _initialize_doc_intelligence_client(secrets)
    if not st.session_state[SESSION_STATE_DOC_INTEL_CLIENT]: init_success = False

    st.session_state[SESSION_STATE_SPEECH_CONFIG] = _initialize_speech_config(secrets)
    if not st.session_state[SESSION_STATE_SPEECH_CONFIG]: init_success = False

    st.session_state[SESSION_STATE_BLOB_CLIENT] = _initialize_blob_service_client(secrets)
    if not st.session_state[SESSION_STATE_BLOB_CLIENT]: init_success = False

    # Search Client (Index specific - initialize later or with default index?)
    # We won't initialize a default Search client here, do it in the Search page.
    st.session_state[SESSION_STATE_SEARCH_CLIENT] = None


    # Final check and logging
    if not init_success:
        logger.error("One or more Azure clients failed to initialize properly.")
        # Optionally display a more prominent error in the Streamlit app
        # st.error("Error: Could not initialize all required Azure services. Some features may be unavailable. Please check logs and configuration.")

    st.session_state[session_key] = init_success # Use the specific key
    logger.info(f"Azure client initialization complete. Overall Success: {init_success}")
    return init_success


# --- Main Execution (Example Usage/Test) ---
# This block helps test client initialization when running the script directly.
if __name__ == "__main__":
    print("--- Testing Azure Client Initialization into Session State (Simulated) ---")

    # Simulate Streamlit's session state for local testing
    if 'session_state' not in locals():
        st_session_state_simulation = {}
        # Define a simple class to mimic st.session_state behavior for testing
        class MockSessionState:
            def __init__(self, state_dict):
                self._state = state_dict
            def get(self, key, default=None):
                return self._state.get(key, default)
            def __setitem__(self, key, value):
                self._state[key] = value
            def __getitem__(self, key):
                return self._state[key]
            def __contains__(self, key):
                return key in self._state
        st.session_state = MockSessionState(st_session_state_simulation)


    # Load .env file for local testing if it exists
    try:
        from dotenv import load_dotenv
        if load_dotenv():
             print("Loaded environment variables from .env file.")
        else:
             print("No .env file found or it is empty.")
    except ImportError:
        print("dotenv library not found, skipping .env load. Ensure environment variables are set.")

    # Initialize clients into the simulated session state
    success = initialize_clients_in_session_state()

    if success:
        print("\nClients initialized and stored in session state (simulated):")
        # Access clients from the simulated state
        print(f"  - Recipe Container Client: {'OK' if st.session_state.get(SESSION_STATE_RECIPE_CONTAINER) else 'FAILED'}")
        print(f"  - OpenAI Client: {'OK' if st.session_state.get(SESSION_STATE_OPENAI_CLIENT) else 'FAILED'}")
        print(f"  - Language Client: {'OK' if st.session_state.get(SESSION_STATE_LANGUAGE_CLIENT) else 'FAILED'}")
        print(f"  - Vision Client: {'OK' if st.session_state.get(SESSION_STATE_VISION_CLIENT) else 'FAILED'}")
        print(f"  - Doc Intel Client: {'OK' if st.session_state.get(SESSION_STATE_DOC_INTEL_CLIENT) else 'FAILED'}")
        print(f"  - Speech Config: {'OK' if st.session_state.get(SESSION_STATE_SPEECH_CONFIG) else 'FAILED'}")
        print(f"  - Blob Client: {'OK' if st.session_state.get(SESSION_STATE_BLOB_CLIENT) else 'FAILED'}")
        print("\nSecrets stored (keys only):")
        if SESSION_STATE_SECRETS in st.session_state and st.session_state[SESSION_STATE_SECRETS]:
            print(f"     {list(st.session_state[SESSION_STATE_SECRETS].keys())}")
        else:
            print("     No secrets dictionary found in state.")
    else:
        print("\n[!] Failed to initialize Azure clients into session state.")

    print("\n--- Test Complete ---")
