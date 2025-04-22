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
from typing import Dict, Optional

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Global Variables (Consider managing these more dynamically if needed) ---
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
    "StorageAccountKey", # Or Connection String if preferred
    "SearchServiceEndpoint",
    "SearchAdminKey"
]

# --- Key Vault Client Initialization ---

def get_key_vault_client() -> Optional[SecretClient]:
    """
    Initializes and returns an Azure Key Vault SecretClient using Managed Identity.

    Reads the Key Vault URI from the AZURE_KEY_VAULT_URI environment variable.
    Uses ManagedIdentityCredential suitable for Azure hosting environments (App Service, ACA).
    Includes DefaultAzureCredential as a fallback for local development if configured.

    Returns:
        SecretClient: An authenticated client to interact with Key Vault secrets.
        None: If the Key Vault URI is not set or authentication fails.
    """
    key_vault_uri = os.getenv("AZURE_KEY_VAULT_URI")
    if not key_vault_uri:
        logger.error("Azure Key Vault URI not found. Set the AZURE_KEY_VAULT_URI environment variable.")
        return None

    try:
        # Use ManagedIdentityCredential for Azure environments (App Service, ACA, VMs, etc.)
        # Use DefaultAzureCredential as a fallback for local dev (reads env vars, Azure CLI, etc.)
        # ChainedTokenCredential tries them in order.
        credential = ChainedTokenCredential([ManagedIdentityCredential(), DefaultAzureCredential()])
        logger.info(f"Attempting to create SecretClient for Key Vault: {key_vault_uri}")
        kv_client = SecretClient(vault_url=key_vault_uri, credential=credential)
        logger.info("SecretClient created successfully.")
        return kv_client
    except ClientAuthenticationError as auth_error:
        logger.error(f"Authentication failed for Key Vault '{key_vault_uri}': {auth_error}", exc_info=True)
        # Log details about Managed Identity setup if possible/relevant
        if "ManagedIdentityCredential" in str(auth_error):
             logger.error("Ensure Managed Identity is enabled and has 'Get Secrets' permission on the Key Vault.")
        return None
    except Exception as e:
        logger.error(f"An unexpected error occurred while creating SecretClient for Key Vault '{key_vault_uri}': {e}", exc_info=True)
        return None

# --- Function to Retrieve Secrets ---

def get_secrets_from_key_vault(secret_names: List[str] = EXPECTED_SECRET_NAMES) -> Optional[Dict[str, str]]:
    """
    Retrieves a dictionary of specified secrets from Azure Key Vault.

    Args:
        secret_names (List[str]): A list of secret names to retrieve.
                                   Defaults to EXPECTED_SECRET_NAMES.

    Returns:
        Optional[Dict[str, str]]: A dictionary where keys are secret names
                                  and values are the secret values.
                                  Returns None if the Key Vault client cannot be
                                  initialized or a critical error occurs.
                                  Missing secrets will log a warning but not cause failure.
    """
    kv_client = get_key_vault_client()
    if not kv_client:
        logger.error("Failed to initialize Key Vault client. Cannot retrieve secrets.")
        return None

    retrieved_secrets: Dict[str, str] = {}
    logger.info(f"Retrieving secrets from Key Vault: {', '.join(secret_names)}")

    for secret_name in secret_names:
        try:
            # logger.debug(f"Attempting to retrieve secret: {secret_name}")
            secret_bundle = kv_client.get_secret(secret_name)
            retrieved_secrets[secret_name] = secret_bundle.value
            # logger.debug(f"Successfully retrieved secret: {secret_name}")
        except ResourceNotFoundError:
            logger.warning(f"Secret '{secret_name}' not found in Key Vault '{kv_client.vault_url}'.")
            # Decide if missing secrets should be fatal or just logged
            # For now, we log and continue, the calling code needs to handle missing keys
        except ClientAuthenticationError as auth_error:
            logger.error(f"Authentication error while retrieving secret '{secret_name}': {auth_error}", exc_info=True)
            # This likely indicates a permission issue for the Managed Identity
            return None # Treat auth errors during retrieval as potentially fatal
        except Exception as e:
            logger.error(f"An unexpected error occurred retrieving secret '{secret_name}': {e}", exc_info=True)
            # Depending on desired robustness, might continue or return None

    logger.info(f"Retrieved {len(retrieved_secrets)} out of {len(secret_names)} requested secrets.")
    return retrieved_secrets

# --- Placeholder Functions for Other Clients ---
# These functions would use the retrieved secrets to initialize other clients

# def get_cosmos_client(secrets: Dict[str, str]) -> Optional[CosmosClient]:
#     """Initializes and returns an Azure Cosmos DB client."""
#     endpoint = secrets.get("CosmosDBEndpoint")
#     key = secrets.get("CosmosDBKey") # Or use Managed Identity if Cosmos supports it directly
#     if not endpoint or not key:
#         logger.error("Cosmos DB endpoint or key not found in retrieved secrets.")
#         return None
#     try:
#         # from azure.cosmos import CosmosClient
#         # client = CosmosClient(url=endpoint, credential=key)
#         # return client
#         logger.info("Cosmos DB Client initialized (Placeholder).") # Placeholder
#         return "MockCosmosClient" # Placeholder
#     except Exception as e:
#         logger.error(f"Failed to initialize Cosmos DB client: {e}", exc_info=True)
#         return None

# def get_openai_client(secrets: Dict[str, str]) -> Optional[OpenAI]: # Or AzureOpenAI if that SDK existed
#      """Initializes and returns an Azure OpenAI client."""
#      # ... implementation using secrets['AzureOpenAIEndpoint'], secrets['AzureOpenAIKey'] ...
#      # ... and configuring openai package for Azure type ...
#      pass

# def get_ai_services_client(secrets: Dict[str, str]) -> Optional[CognitiveServicesCredentials]: # Example type
#      """Initializes credentials/client for unified AI Services."""
#      # ... implementation using secrets['AIServicesEndpoint'], secrets['AIServicesKey'] ...
#      pass

# def get_search_client(secrets: Dict[str, str]) -> Optional[SearchClient]:
#      """Initializes and returns an Azure AI Search client."""
#      # ... implementation using secrets['SearchServiceEndpoint'], secrets['SearchAdminKey'] ...
#      pass

# def get_blob_service_client(secrets: Dict[str, str]) -> Optional[BlobServiceClient]:
#      """Initializes and returns an Azure Blob Storage client."""
#      # ... implementation using secrets['StorageAccountName'], secrets['StorageAccountKey'] or Conn String ...
#      pass


# --- Main Execution (Example Usage/Test) ---
if __name__ == "__main__":
    print("Attempting to retrieve secrets from Key Vault using Managed Identity/Default Creds...")

    # Example: Ensure AZURE_KEY_VAULT_URI is set if running locally
    # os.environ['AZURE_KEY_VAULT_URI'] = 'YOUR_KEY_VAULT_URI_HERE_FOR_TESTING'

    secrets = get_secrets_from_key_vault()

    if secrets:
        print("\nSuccessfully retrieved secrets:")
        for name, value_part in secrets.items():
            # Print only a part of the secret for security
            print(f"  - {name}: {value_part[:4]}...{value_part[-4:]}" if len(value_part) > 8 else f"  - {name}: Present")

        # Example: Initialize other clients (using placeholder functions for now)
        # cosmos_client = get_cosmos_client(secrets)
        # if cosmos_client:
        #     print("\nCosmos DB Client Initialized (Placeholder).")
        # else:
        #     print("\nFailed to initialize Cosmos DB Client.")

        # ... initialize other clients ...

    else:
        print("\nFailed to retrieve secrets from Key Vault.")

