# -*- coding: utf-8 -*-
"""
Module for initializing and providing clients for specific Azure AI services.
Uses Managed Identity to authenticate to Key Vault and retrieve individual
service keys and endpoints. Stores initialized clients in Streamlit session state.
"""

import os
import logging
import streamlit as st
from azure.identity import ManagedIdentityCredential, DefaultAzureCredential, ChainedTokenCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import ResourceNotFoundError, ClientAuthenticationError
from azure.core.credentials import AzureKeyCredential
from azure.cosmos import CosmosClient, DatabaseProxy, ContainerProxy
from azure.storage.blob import BlobServiceClient
from azure.search.documents import SearchClient
from azure.ai.textanalytics import TextAnalyticsClient # Language
from azure.ai.vision.imageanalysis import ImageAnalysisClient # Vision
from azure.ai.documentintelligence import DocumentIntelligenceClient # Document Intelligence
from azure.cognitiveservices.speech import SpeechConfig # Speech
from openai import AzureOpenAI
from typing import Dict, Optional, List, Union, Tuple
import re

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)
logging.getLogger("azure.core.pipeline.policies.http_logging_policy").setLevel(logging.WARNING)
logging.getLogger("azure.identity._internal.managed_identity_client").setLevel(logging.WARNING)

# --- Global Variables ---
# UPDATED: List of expected secret names for DEDICATED services
EXPECTED_SECRET_NAMES = [
    "LanguageServiceKey", "LanguageServiceEndpoint",
    "VisionServiceKey", "VisionServiceEndpoint",
    "SpeechServiceKey", "SpeechServiceRegion", # Speech often uses Key + Region
    "DocIntelKey", "DocIntelEndpoint",
    "AzureOpenAIKey", "AzureOpenAIEndpoint",
    "CosmosDBEndpoint", "CosmosDBKey",
    "StorageAccountName", "StorageAccountKey", # Or StorageConnectionString
    "SearchServiceEndpoint", "SearchAdminKey"
]
# Session state keys remain largely the same conceptually
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
SESSION_STATE_SEARCH_CLIENT = 'search_client'
SESSION_STATE_BLOB_CLIENT = 'blob_client'
SESSION_STATE_CLIENTS_INITIALIZED = 'azure_clients_initialized'

# --- Credential Initialization (Centralized) ---
try:
    AZURE_CREDENTIAL = ChainedTokenCredential(ManagedIdentityCredential(), DefaultAzureCredential())
    logger.info("Azure credential initialized using ChainedTokenCredential.")
except Exception as e:
    logger.error(f"Failed to initialize Azure credential: {e}", exc_info=True)
    AZURE_CREDENTIAL = None

# --- Key Vault Client Initialization ---
def _get_key_vault_client() -> Optional[SecretClient]:
    """Internal function to initialize Key Vault client."""
    key_vault_uri = os.getenv("AZURE_KEY_VAULT_URI")
    if not key_vault_uri or not AZURE_CREDENTIAL:
        logger.error("AZURE_KEY_VAULT_URI env var not set or Azure credential failed.")
        return None
    try:
        logger.info(f"Attempting to create SecretClient for Key Vault: {key_vault_uri}")
        kv_client = SecretClient(vault_url=key_vault_uri, credential=AZURE_CREDENTIAL)
        list(kv_client.list_properties_of_secrets()) # Verify connection
        logger.info("SecretClient created and verified successfully.")
        return kv_client
    except Exception as e:
        logger.error(f"Failed creating/verifying SecretClient for '{key_vault_uri}': {e}", exc_info=True)
        return None

# --- Function to Retrieve Secrets ---
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
            logger.warning(f"Secret '{secret_name}' not found in Key Vault '{kv_client.vault_url}'.")
        except ClientAuthenticationError as auth_error:
            logger.error(f"Authentication error retrieving secret '{secret_name}': {auth_error}. Stopping.", exc_info=True)
            return None # Fatal
        except Exception as e:
            logger.error(f"Unexpected error retrieving secret '{secret_name}': {e}. Skipping.", exc_info=True)
    logger.info(f"Finished retrieving secrets. Got values for {retrieved_count}/{len(secret_names)} secrets.")
    return retrieved_secrets


# --- Initialization Functions for Service Clients (Using Specific Credentials) ---

def _initialize_cosmos_client(secrets: Dict[str, Optional[str]]) -> Optional[CosmosClient]:
    """Initializes Azure Cosmos DB client using specific key/endpoint."""
    endpoint = secrets.get("CosmosDBEndpoint")
    key = secrets.get("CosmosDBKey")
    if not endpoint or not key:
        logger.error("Cosmos DB endpoint or key not found for client initialization.")
        return None
    try:
        client = CosmosClient(url=endpoint, credential=key)
        list(client.list_databases()) # Test connection
        logger.info("Cosmos DB Client initialized successfully.")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize Cosmos DB client: {e}", exc_info=True)
        return None

def _initialize_openai_client(secrets: Dict[str, Optional[str]]) -> Optional[AzureOpenAI]:
     """Initializes Azure OpenAI client using specific key/endpoint or AAD."""
     endpoint = secrets.get("AzureOpenAIEndpoint")
     api_key = secrets.get("AzureOpenAIKey")
     api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview")
     if not endpoint:
         logger.error("Azure OpenAI endpoint not found.")
         return None
     credential_to_use = None
     auth_method = "API Key"
     if not api_key:
         logger.warning("Azure OpenAI key not found. Attempting Azure Credentials.")
         if AZURE_CREDENTIAL: credential_to_use = AZURE_CREDENTIAL; auth_method = "Azure AD/Managed Identity"
         else: logger.error("Azure OpenAI key missing and Azure Credential unavailable."); return None
     try:
         logger.info(f"Initializing Azure OpenAI Client (endpoint: {endpoint}, auth: {auth_method})")
         if credential_to_use: client = AzureOpenAI(azure_endpoint=endpoint, api_version=api_version, azure_ad_token_provider=credential_to_use)
         else: client = AzureOpenAI(azure_endpoint=endpoint, api_version=api_version, api_key=api_key)
         try: client.models.list(); logger.info("Azure OpenAI Client initialized and verified.")
         except Exception as test_error: logger.warning(f"Azure OpenAI Client initialized, but test call failed: {test_error}.")
         return client
     except Exception as e:
         logger.error(f"Failed to initialize Azure OpenAI client: {e}", exc_info=True)
         return None

def _initialize_language_client(secrets: Dict[str, Optional[str]]) -> Optional[TextAnalyticsClient]:
    """Initializes Azure AI Language client using specific key/endpoint."""
    endpoint = secrets.get("LanguageServiceEndpoint")
    key = secrets.get("LanguageServiceKey")
    if not endpoint or not key:
        logger.error("Language Service endpoint or key not found.")
        return None
    try:
        credential = AzureKeyCredential(key)
        logger.info(f"Initializing Text Analytics Client for endpoint: {endpoint}")
        client = TextAnalyticsClient(endpoint=endpoint, credential=credential)
        logger.info("Text Analytics Client initialized successfully.")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize Text Analytics client: {e}", exc_info=True)
        return None

def _initialize_vision_client(secrets: Dict[str, Optional[str]]) -> Optional[ImageAnalysisClient]:
    """Initializes Azure AI Vision client using specific key/endpoint."""
    endpoint = secrets.get("VisionServiceEndpoint")
    key = secrets.get("VisionServiceKey")
    if not endpoint or not key:
        logger.error("Vision Service endpoint or key not found.")
        return None
    try:
        credential = AzureKeyCredential(key)
        logger.info(f"Initializing Image Analysis Client for endpoint: {endpoint}")
        client = ImageAnalysisClient(endpoint=endpoint, credential=credential)
        logger.info("Image Analysis Client initialized successfully.")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize Image Analysis client: {e}", exc_info=True)
        return None

def _initialize_doc_intelligence_client(secrets: Dict[str, Optional[str]]) -> Optional[DocumentIntelligenceClient]:
    """Initializes Azure AI Document Intelligence client using specific key/endpoint."""
    endpoint = secrets.get("DocIntelEndpoint")
    key = secrets.get("DocIntelKey")
    if not endpoint or not key:
        logger.error("Document Intelligence endpoint or key not found.")
        return None
    try:
        credential = AzureKeyCredential(key)
        logger.info(f"Initializing Document Intelligence Client for endpoint: {endpoint}")
        client = DocumentIntelligenceClient(endpoint=endpoint, credential=credential)
        logger.info("Document Intelligence Client initialized successfully.")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize Document Intelligence client: {e}", exc_info=True)
        return None

def _initialize_speech_config(secrets: Dict[str, Optional[str]]) -> Optional[SpeechConfig]:
    """Initializes Azure AI Speech configuration object using specific key/region."""
    key = secrets.get("SpeechServiceKey")
    region = secrets.get("SpeechServiceRegion") # Expecting region directly now
    if not key or not region:
         logger.error(f"Speech Service key ({key is not None}) or region ({region}) not found in secrets.")
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
     """Initializes Azure AI Search client using specific key/endpoint."""
     endpoint = secrets.get("SearchServiceEndpoint")
     key = secrets.get("SearchAdminKey")
     if not endpoint or not key:
         logger.error("Search service endpoint or key not found.")
         return None
     if not index_name: logger.error("Search index name required."); return None
     try:
         credential = AzureKeyCredential(key)
         logger.info(f"Initializing Search Client for endpoint: {endpoint}, index: {index_name}")
         client = SearchClient(endpoint=endpoint, index_name=index_name, credential=credential)
         client.get_document_count() # Test connection
         logger.info("Search Client initialized and verified successfully.")
         return client
     except Exception as e:
         logger.error(f"Failed to initialize or verify Search client: {e}", exc_info=True)
         return None

def _initialize_blob_service_client(secrets: Dict[str, Optional[str]]) -> Optional[BlobServiceClient]:
     """Initializes Azure Blob Storage client using specific key/name or connection string or AAD."""
     account_name = secrets.get("StorageAccountName")
     account_key = secrets.get("StorageAccountKey")
     connection_string = secrets.get("StorageConnectionString")
     credential_to_use: Union[str, ManagedIdentityCredential, DefaultAzureCredential, None] = None
     auth_method = "Unknown"
     # Prioritize Connection String if provided
     if connection_string: auth_method = "Connection String"
     elif account_name and account_key:
         connection_string = f"DefaultEndpointsProtocol=https;AccountName={account_name};AccountKey={account_key};EndpointSuffix=core.windows.net"
         auth_method = "Account Key (via constructed CS)"
     elif account_name and AZURE_CREDENTIAL:
         credential_to_use = AZURE_CREDENTIAL
         auth_method = "Azure AD/Managed Identity"
     elif not account_name: logger.error("Storage account name not found."); return None
     else: logger.error("No valid credential found for Blob Storage."); return None
     try:
         account_url = f"https://{account_name}.blob.core.windows.net" if account_name else None
         logger.info(f"Initializing Blob Service Client for account: {account_name} using {auth_method}")
         if connection_string: blob_service_client = BlobServiceClient.from_connection_string(connection_string)
         elif account_url and credential_to_use: blob_service_client = BlobServiceClient(account_url=account_url, credential=credential_to_use)
         else: logger.error("Logic error: Could not determine Blob Storage client init method."); return None
         blob_service_client.get_service_properties() # Test connection
         logger.info("Blob Service Client initialized and verified successfully.")
         return blob_service_client
     except Exception as e:
         logger.error(f"Failed to initialize or verify Blob Service client: {e}", exc_info=True)
         return None


# --- Main Initialization Function for Streamlit App ---

def initialize_clients_in_session_state(force_reload: bool = False):
    """
    Initializes all necessary Azure clients using specific service credentials
    retrieved from Key Vault and stores them in st.session_state.
    """
    session_key = f"{__name__}_clients_initialized"
    if not force_reload and st.session_state.get(session_key):
        return True # Already initialized

    logger.info(f"Initializing Azure clients (force_reload={force_reload})...")
    st.session_state[session_key] = False # Mark as initializing

    # 1. Get Secrets from Key Vault
    kv_client = _get_key_vault_client()
    if not kv_client: st.error("Fatal: Could not initialize Key Vault client."); return False
    secrets = _get_secrets_from_key_vault(kv_client)
    if secrets is None: st.error("Fatal: Failed to retrieve secrets from Key Vault."); return False
    st.session_state[SESSION_STATE_SECRETS] = secrets
    logger.info("Secrets loaded into session state.")

    # 2. Initialize and Store Clients using specific credentials
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
        except Exception as e: logger.error(f"Failed to get Cosmos DB containers: {e}", exc_info=True); init_success = False
    else: init_success = False

    # Initialize other clients
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

    # Search Client (Initialize later or with default index?)
    st.session_state[SESSION_STATE_SEARCH_CLIENT] = None

    # Final check and logging
    if not init_success:
        logger.error("One or more Azure clients failed to initialize properly.")

    st.session_state[session_key] = init_success
    logger.info(f"Azure client initialization complete. Overall Success: {init_success}")
    return init_success


# --- Main Execution (Example Usage/Test) ---
if __name__ == "__main__":
    print("--- Testing Azure Client Initialization (Specific Services) into Session State (Simulated) ---")
    # ... (Test block remains the same as previous version, will test the new init logic) ...
    if 'session_state' not in locals():
        st_session_state_simulation = {}
        class MockSessionState:
            def __init__(self, state_dict): self._state = state_dict
            def get(self, key, default=None): return self._state.get(key, default)
            def __setitem__(self, key, value): self._state[key] = value
            def __getitem__(self, key): return self._state[key]
            def __contains__(self, key): return key in self._state
        st.session_state = MockSessionState(st_session_state_simulation)
    try:
        from dotenv import load_dotenv
        if load_dotenv(): print("Loaded environment variables from .env file.")
        else: print("No .env file found or it is empty.")
    except ImportError: print("dotenv library not found, skipping .env load.")
    success = initialize_clients_in_session_state()
    if success:
        print("\nClients initialized and stored in session state (simulated):")
        print(f"  - Recipe Container Client: {'OK' if st.session_state.get(SESSION_STATE_RECIPE_CONTAINER) else 'FAILED'}")
        print(f"  - OpenAI Client: {'OK' if st.session_state.get(SESSION_STATE_OPENAI_CLIENT) else 'FAILED'}")
        print(f"  - Language Client: {'OK' if st.session_state.get(SESSION_STATE_LANGUAGE_CLIENT) else 'FAILED'}")
        print(f"  - Vision Client: {'OK' if st.session_state.get(SESSION_STATE_VISION_CLIENT) else 'FAILED'}")
        print(f"  - Doc Intel Client: {'OK' if st.session_state.get(SESSION_STATE_DOC_INTEL_CLIENT) else 'FAILED'}")
        print(f"  - Speech Config: {'OK' if st.session_state.get(SESSION_STATE_SPEECH_CONFIG) else 'FAILED'}")
        print(f"  - Blob Client: {'OK' if st.session_state.get(SESSION_STATE_BLOB_CLIENT) else 'FAILED'}")
        print("\nSecrets stored (keys only):")
        if SESSION_STATE_SECRETS in st.session_state and st.session_state[SESSION_STATE_SECRETS]: print(f"     {list(st.session_state[SESSION_STATE_SECRETS].keys())}")
        else: print("     No secrets dictionary found in state.")
    else: print("\n[!] Failed to initialize Azure clients into session state.")
    print("\n--- Test Complete ---")

