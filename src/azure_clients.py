# -*- coding: utf-8 -*-
"""
Module for initializing and providing clients for specific Azure AI services.
Uses Managed Identity to authenticate to Key Vault and retrieve individual
service keys, endpoints, and configurations.
Caches retrieved secrets using st.cache_resource.
Stores initialized clients in Streamlit session state.
"""

import os
import logging
import streamlit as st # Required for caching and session state
from azure.identity import ManagedIdentityCredential, DefaultAzureCredential, ChainedTokenCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import ResourceNotFoundError, ClientAuthenticationError
from azure.core.credentials import AzureKeyCredential
from azure.cosmos import CosmosClient, DatabaseProxy, ContainerProxy
from azure.storage.blob import BlobServiceClient
from azure.search.documents import SearchClient
from azure.ai.textanalytics import TextAnalyticsClient # Language (If re-added later)
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
# List of expected secret names
EXPECTED_SECRET_NAMES = [
    # "LanguageServiceKey", "LanguageServiceEndpoint", # Removed as per previous decision
    "VisionServiceKey", "VisionServiceEndpoint",
    "SpeechServiceKey", "SpeechServiceRegion",
    "DocIntelKey", "DocIntelEndpoint",
    "AzureOpenAIKey", "AzureOpenAIEndpoint",
    "CosmosDBEndpoint", "CosmosDBKey",
    "StorageAccountName", "StorageAccountKey", # Or StorageConnectionString
    "SearchServiceEndpoint", "SearchAdminKey",
    "SearchIndexName"
]
# Session state keys
SESSION_STATE_SECRETS = 'azure_secrets' # Still store secrets in session state after caching
SESSION_STATE_COSMOS_CLIENT = 'cosmos_client'
SESSION_STATE_RECIPE_CONTAINER = 'recipe_container'
SESSION_STATE_PANTRY_CONTAINER = 'pantry_container'
SESSION_STATE_INGREDIENT_CONTAINER = 'ingredient_container'
SESSION_STATE_OPENAI_CLIENT = 'openai_client'
# SESSION_STATE_LANGUAGE_CLIENT = 'language_client' # Removed
SESSION_STATE_VISION_CLIENT = 'vision_client'
SESSION_STATE_DOC_INTEL_CLIENT = 'doc_intel_client'
SESSION_STATE_SPEECH_CONFIG = 'speech_config'
SESSION_STATE_SEARCH_CLIENT = 'search_client'
SESSION_STATE_BLOB_CLIENT = 'blob_client'
SESSION_STATE_CLIENTS_INITIALIZED = 'azure_clients_initialized_status'


# --- Credential Initialization (Centralized) ---
try:
    AZURE_CREDENTIAL = ChainedTokenCredential([ManagedIdentityCredential(), DefaultAzureCredential()])
    logger.info("Azure credential initialized using ChainedTokenCredential.")
except Exception as e:
    logger.error(f"Failed to initialize Azure credential: {e}", exc_info=True)
    AZURE_CREDENTIAL = None

# --- Key Vault Client Initialization (Internal Helper) ---
# This function itself is NOT cached, as the client might depend on session specifics if auth changes
def _get_key_vault_client() -> Optional[SecretClient]:
    """Internal function to initialize Key Vault client."""
    key_vault_uri = os.getenv("AZURE_KEY_VAULT_URI")
    if not key_vault_uri or not AZURE_CREDENTIAL:
        logger.error("AZURE_KEY_VAULT_URI env var not set or Azure credential failed.")
        return None
    try:
        # logger.info(f"Attempting to create SecretClient for Key Vault: {key_vault_uri}")
        kv_client = SecretClient(vault_url=key_vault_uri, credential=AZURE_CREDENTIAL)
        # Test call removed from here, will happen in the cached function
        # list(kv_client.list_properties_of_secrets(max_results=1))
        # logger.info("SecretClient created successfully (connection not verified here).")
        return kv_client
    except Exception as e:
        logger.error(f"Failed creating SecretClient for '{key_vault_uri}': {e}", exc_info=True)
        return None

# --- Function to Retrieve Secrets (Internal Helper) ---
def _get_secrets_from_key_vault(kv_client: SecretClient, secret_names: List[str] = EXPECTED_SECRET_NAMES) -> Optional[Dict[str, Optional[str]]]:
    """Internal function to retrieve secrets using an existing KV client."""
    # ... (implementation remains the same) ...
    retrieved_secrets: Dict[str, Optional[str]] = {name: None for name in secret_names}; logger.info(f"Retrieving secrets from Key Vault: {', '.join(secret_names)}"); retrieved_count = 0
    for secret_name in secret_names:
        try: secret_bundle = kv_client.get_secret(secret_name); retrieved_secrets[secret_name] = secret_bundle.value; retrieved_count += 1
        except ResourceNotFoundError: logger.warning(f"Secret '{secret_name}' not found in Key Vault '{kv_client.vault_url}'.")
        except ClientAuthenticationError as auth_error: logger.error(f"Authentication error retrieving secret '{secret_name}': {auth_error}. Stopping.", exc_info=True); return None
        except Exception as e: logger.error(f"Unexpected error retrieving secret '{secret_name}': {e}. Skipping.", exc_info=True)
    logger.info(f"Finished retrieving secrets. Got values for {retrieved_count}/{len(secret_names)} secrets.")
    return retrieved_secrets

# --- NEW: Cached Function to Load Secrets ---
@st.cache_resource(show_spinner="Connecting to Key Vault to load secrets...")
def _load_all_secrets_cached() -> Optional[Dict[str, Optional[str]]]:
    """
    Retrieves all necessary secrets from Key Vault.
    Uses @st.cache_resource to cache the result across sessions
    within the same Streamlit server process.
    Performs an initial connection test.
    """
    logger.info("Executing _load_all_secrets_cached (should run only once per process unless cleared)...")
    kv_client = _get_key_vault_client()
    if not kv_client:
        logger.error("Failed to get Key Vault client in cached function.")
        return None # Indicate failure

    # Verify connection within the cached function
    try:
        logger.debug("Verifying Key Vault connection inside cached function...")
        list(kv_client.list_properties_of_secrets(max_results=1))
        logger.info("Key Vault connection verified.")
    except Exception as e:
        logger.error(f"Failed to connect or list secrets in Key Vault within cached function: {e}", exc_info=True)
        st.error(f"Error connecting to Key Vault: {e}. Check URI and permissions.") # Show error in UI
        return None # Indicate failure

    secrets = _get_secrets_from_key_vault(kv_client)
    if secrets is None: # Check if secret retrieval itself failed critically
         logger.error("Failed to retrieve secrets from Key Vault within cached function.")
         st.error("Failed to retrieve necessary secrets from Key Vault.")
         return None

    logger.info("Secrets successfully loaded and cached.")
    return secrets

# --- Initialization Functions for Service Clients (Internal Helpers - Unchanged) ---
# These functions still take the secrets dict as input

def _initialize_cosmos_client(secrets: Dict[str, Optional[str]]) -> Optional[CosmosClient]:
    """Initializes Azure Cosmos DB client."""
    # ... (implementation remains the same) ...
    endpoint = secrets.get("CosmosDBEndpoint"); key = secrets.get("CosmosDBKey")
    if not endpoint or not key: logger.error("Cosmos DB endpoint or key not found."); return None
    try: client = CosmosClient(url=endpoint, credential=key); list(client.list_databases()); logger.info("Cosmos DB Client initialized."); return client
    except Exception as e: logger.error(f"Failed to initialize Cosmos DB client: {e}", exc_info=True); return None

def _initialize_openai_client(secrets: Dict[str, Optional[str]]) -> Optional[AzureOpenAI]:
     """Initializes Azure OpenAI client."""
     # ... (implementation remains the same) ...
     endpoint = secrets.get("AzureOpenAIEndpoint"); api_key = secrets.get("AzureOpenAIKey"); api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview")
     if not endpoint: logger.error("Azure OpenAI endpoint not found."); return None
     credential_to_use = None; auth_method = "API Key"
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
     except Exception as e: logger.error(f"Failed to initialize Azure OpenAI client: {e}", exc_info=True); return None

def _get_ai_services_credential(secrets: Dict[str, Optional[str]], service_key_name: str) -> Optional[AzureKeyCredential]:
     """Creates an AzureKeyCredential using a specific service key name."""
     # ... (implementation remains the same) ...
     key = secrets.get(service_key_name);
     if not key: logger.error(f"AI Service key '{service_key_name}' not found."); return None
     return AzureKeyCredential(key)

# REMOVED _initialize_language_client function

def _initialize_vision_client(secrets: Dict[str, Optional[str]]) -> Optional[ImageAnalysisClient]:
    """Initializes Azure AI Vision client."""
    # ... (implementation remains the same) ...
    endpoint = secrets.get("VisionServiceEndpoint"); credential = _get_ai_services_credential(secrets, "VisionServiceKey")
    if not endpoint or not credential: logger.error("Vision Service endpoint or credential not available."); return None
    try: client = ImageAnalysisClient(endpoint=endpoint, credential=credential); logger.info("Image Analysis Client initialized."); return client
    except Exception as e: logger.error(f"Failed to initialize Image Analysis client: {e}", exc_info=True); return None

def _initialize_doc_intelligence_client(secrets: Dict[str, Optional[str]]) -> Optional[DocumentIntelligenceClient]:
    """Initializes Azure AI Document Intelligence client."""
    # ... (implementation remains the same) ...
    endpoint = secrets.get("DocIntelEndpoint"); credential = _get_ai_services_credential(secrets, "DocIntelKey")
    if not endpoint or not credential: logger.error("Document Intelligence endpoint or credential not available."); return None
    try: client = DocumentIntelligenceClient(endpoint=endpoint, credential=credential); logger.info("Document Intelligence Client initialized."); return client
    except Exception as e: logger.error(f"Failed to initialize Document Intelligence client: {e}", exc_info=True); return None

def _initialize_speech_config(secrets: Dict[str, Optional[str]]) -> Optional[SpeechConfig]:
    """Initializes Azure AI Speech configuration object."""
    # ... (implementation remains the same) ...
    key = secrets.get("SpeechServiceKey"); region = secrets.get("SpeechServiceRegion")
    if not key or not region: logger.error(f"Speech Service key ({key is not None}) or region ({region}) not found."); return None
    try: speech_config = SpeechConfig(subscription=key, region=region); logger.info("Speech Config initialized."); return speech_config
    except Exception as e: logger.error(f"Failed to initialize Speech Config: {e}", exc_info=True); return None

def _initialize_search_client(secrets: Dict[str, Optional[str]]) -> Optional[SearchClient]:
     """Initializes Azure AI Search client."""
     # ... (implementation remains the same) ...
     endpoint = secrets.get("SearchServiceEndpoint"); key = secrets.get("SearchAdminKey"); index_name = secrets.get("SearchIndexName")
     if not endpoint or not key or not index_name: logger.error(f"Search endpoint ({endpoint is not None}), key ({key is not None}), or index name ({index_name is not None}) not found."); return None
     try:
         credential = AzureKeyCredential(key); client = SearchClient(endpoint=endpoint, index_name=index_name, credential=credential)
         client.get_document_count(); logger.info(f"Search Client initialized for index '{index_name}'.")
         return client
     except Exception as e: logger.warning(f"Failed to initialize Search client for index '{index_name}': {e}", exc_info=True); return None

def _initialize_blob_service_client(secrets: Dict[str, Optional[str]]) -> Optional[BlobServiceClient]:
     """Initializes Azure Blob Storage client."""
     # ... (implementation remains the same) ...
     account_name = secrets.get("StorageAccountName"); account_key = secrets.get("StorageAccountKey"); connection_string = secrets.get("StorageConnectionString")
     credential_to_use: Union[str, ManagedIdentityCredential, DefaultAzureCredential, None] = None; auth_method = "Unknown"
     if connection_string: auth_method = "Connection String"
     elif account_name and account_key: connection_string = f"DefaultEndpointsProtocol=https;AccountName={account_name};AccountKey={account_key};EndpointSuffix=core.windows.net"; auth_method = "Account Key (via constructed CS)"
     elif account_name and AZURE_CREDENTIAL: credential_to_use = AZURE_CREDENTIAL; auth_method = "Azure AD/Managed Identity"
     elif not account_name: logger.error("Storage account name not found."); return None
     else: logger.error("No valid credential found for Blob Storage."); return None
     try:
         account_url = f"https://{account_name}.blob.core.windows.net" if account_name else None; logger.info(f"Initializing Blob Service Client for account: {account_name} using {auth_method}")
         if connection_string: blob_service_client = BlobServiceClient.from_connection_string(connection_string)
         elif account_url and credential_to_use: blob_service_client = BlobServiceClient(account_url=account_url, credential=credential_to_use)
         else: logger.error("Logic error: Could not determine Blob Storage client init method."); return None
         blob_service_client.get_service_properties(); logger.info("Blob Service Client initialized.")
         return blob_service_client
     except Exception as e: logger.error(f"Failed to initialize Blob Service client: {e}", exc_info=True); return None


# --- Main Initialization Function for Streamlit App (UPDATED) ---

def initialize_clients_in_session_state(force_reload: bool = False):
    """
    Initializes all necessary Azure clients and stores them in st.session_state.
    Uses @st.cache_resource to efficiently load secrets from Key Vault once per process.
    """
    session_key = SESSION_STATE_CLIENTS_INITIALIZED
    if not force_reload and st.session_state.get(session_key):
        return True # Already initialized in this session

    logger.info(f"Initializing Azure clients in session state (force_reload={force_reload})...")
    st.session_state[session_key] = False # Mark as initializing

    # 1. Load Secrets using the cached function
    secrets = _load_all_secrets_cached() # This call is cached by Streamlit

    if secrets is None: # Check if cached function failed (e.g., KV connection error)
        st.error("Fatal: Failed to load secrets from Key Vault cache.")
        st.session_state[session_key] = False # Ensure flag is False
        # Clear potentially partially loaded secrets?
        if SESSION_STATE_SECRETS in st.session_state:
             del st.session_state[SESSION_STATE_SECRETS]
        return False

    # Store the potentially cached secrets in session state for easy access by other modules if needed
    # Although most client initializers below will use the 'secrets' dict directly
    st.session_state[SESSION_STATE_SECRETS] = secrets
    logger.info("Secrets loaded (potentially from cache) into session state.")

    # 2. Initialize and Store Clients (using the loaded secrets)
    init_success = True # Assume success initially

    # Cosmos DB Client and Containers
    cosmos_client = _initialize_cosmos_client(secrets)
    st.session_state[SESSION_STATE_COSMOS_CLIENT] = cosmos_client
    if cosmos_client:
        db_name = os.getenv("COSMOS_DATABASE_NAME", "MiraiCookDB"); recipe_container_name = os.getenv("RECIPE_CONTAINER_NAME", "Recipes")
        pantry_container_name = os.getenv("PANTRY_CONTAINER_NAME", "Pantry"); ingredient_container_name = os.getenv("INGREDIENT_CONTAINER_NAME", "IngredientsMasterList")
        try:
            db_client = cosmos_client.get_database_client(db_name)
            st.session_state[SESSION_STATE_RECIPE_CONTAINER] = db_client.get_container_client(recipe_container_name)
            st.session_state[SESSION_STATE_PANTRY_CONTAINER] = db_client.get_container_client(pantry_container_name)
            st.session_state[SESSION_STATE_INGREDIENT_CONTAINER] = db_client.get_container_client(ingredient_container_name)
            logger.info("Cosmos DB container clients stored.")
        except Exception as e: logger.error(f"Failed to get Cosmos DB containers: {e}", exc_info=True); init_success = False
    else: 
        init_success = False

    # Initialize other clients
    st.session_state[SESSION_STATE_OPENAI_CLIENT] = _initialize_openai_client(secrets)
    if not st.session_state[SESSION_STATE_OPENAI_CLIENT]: init_success = False

    st.session_state[SESSION_STATE_VISION_CLIENT] = _initialize_vision_client(secrets)
    if not st.session_state[SESSION_STATE_VISION_CLIENT]: init_success = False

    st.session_state[SESSION_STATE_DOC_INTEL_CLIENT] = _initialize_doc_intelligence_client(secrets)
    if not st.session_state[SESSION_STATE_DOC_INTEL_CLIENT]: init_success = False

    st.session_state[SESSION_STATE_SPEECH_CONFIG] = _initialize_speech_config(secrets)
    if not st.session_state[SESSION_STATE_SPEECH_CONFIG]: init_success = False

    st.session_state[SESSION_STATE_BLOB_CLIENT] = _initialize_blob_service_client(secrets)
    if not st.session_state[SESSION_STATE_BLOB_CLIENT]: init_success = False

    # Initialize Search Client
    search_client = _initialize_search_client(secrets)
    st.session_state[SESSION_STATE_SEARCH_CLIENT] = search_client
    if not search_client: logger.warning("Search client initialization failed/skipped.")
    # else: init_success = False # Uncomment if Search is critical

    # Final check and logging
    if not init_success: logger.error("One or more core Azure clients failed to initialize properly.")

    st.session_state[SESSION_STATE_CLIENTS_INITIALIZED] = init_success
    logger.info(f"Azure client initialization complete. Overall Success: {init_success}")
    return init_success


# --- Main Execution (Example Usage/Test) ---
if __name__ == "__main__":
    print("--- Testing Azure Client Initialization with Caching (Simulated) ---")
    # Simulate Streamlit's session state for local testing
    if 'session_state' not in st.session_state:
        st_session_state_simulation = {}
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

    try: from dotenv import load_dotenv; load_dotenv()
    except ImportError: print("dotenv not installed, skipping .env load.")

    if not os.getenv("AZURE_KEY_VAULT_URI"): print("WARNING: AZURE_KEY_VAULT_URI not set.")

    print("\n--- First Initialization Call ---")
    success1 = initialize_clients_in_session_state()
    print(f"First call success: {success1}")
    if success1:
        secrets1 = st.session_state.get(SESSION_STATE_SECRETS)
        print(f"Secrets loaded (first call): {secrets1 is not None}")

    print("\n--- Second Initialization Call (should use cache for secrets) ---")
    # Set force_reload=False (default)
    success2 = initialize_clients_in_session_state()
    print(f"Second call success: {success2}")
    if success2:
        secrets2 = st.session_state.get(SESSION_STATE_SECRETS)
        print(f"Secrets loaded (second call): {secrets2 is not None}")
        # Check if secrets object is the same (depends on caching implementation details)
        # print(f"Secrets object identity same as first call: {secrets1 is secrets2}") # This might be False

    print("\n--- Forcing Reload ---")
    success3 = initialize_clients_in_session_state(force_reload=True)
    print(f"Forced reload call success: {success3}")
    if success3:
        secrets3 = st.session_state.get(SESSION_STATE_SECRETS)
        print(f"Secrets loaded (forced reload): {secrets3 is not None}")

    print("\n--- Test Complete ---")

