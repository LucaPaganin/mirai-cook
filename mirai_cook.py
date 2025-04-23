# -*- coding: utf-8 -*-
"""
Main entry point for the Mirai Cook Streamlit application.
This script sets up the page configuration, initializes Azure clients
via session state, displays the home/welcome page, and shows client status.
Page-specific logic resides in the 'pages/' directory.
"""

import streamlit as st
import logging
import os
import sys

# --- Setup Project Root Path ---
# Allows importing from the 'src' module when run from the project root
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '.'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# --- Import Initialization Function and Keys ---
try:
    # Import the function and the session state keys
    from src.azure_clients import (
        initialize_clients_in_session_state,
        SESSION_STATE_CLIENTS_INITIALIZED,
        # Import keys for individual clients to check status
        SESSION_STATE_COSMOS_CLIENT,
        SESSION_STATE_RECIPE_CONTAINER,
        SESSION_STATE_PANTRY_CONTAINER,
        SESSION_STATE_INGREDIENT_CONTAINER,
        SESSION_STATE_OPENAI_CLIENT,
        SESSION_STATE_LANGUAGE_CLIENT,
        SESSION_STATE_VISION_CLIENT,
        SESSION_STATE_DOC_INTEL_CLIENT,
        SESSION_STATE_SPEECH_CONFIG,
        SESSION_STATE_SEARCH_CLIENT, # Although not initialized by default here
        SESSION_STATE_BLOB_CLIENT
    )
except ImportError as e:
    # Use st.exception to show the error directly in the app during development
    st.exception(f"Fatal Error: Could not import from src.azure_clients. Check PYTHONPATH and file location. Error: {e}")
    # Stop the app if core initialization is missing
    st.stop()

# --- Configure Logging ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)
# Reduce Azure SDK verbosity
logging.getLogger("azure.core.pipeline.policies.http_logging_policy").setLevel(logging.WARNING)
logging.getLogger("azure.identity._internal.managed_identity_client").setLevel(logging.WARNING)


# --- Page Configuration (Must be the first Streamlit command) ---
try:
    st.set_page_config(
        page_title="Mirai Cook AI",
        page_icon="🍳",
        layout="wide",
        initial_sidebar_state="expanded"
    )
except st.errors.StreamlitAPIException as e:
     logger.warning(f"Could not set page config (may be already set): {e}")


# --- Initialize Azure Clients in Session State ---
# This runs once per user session unless explicitly forced or failed previously.
initialization_success = False
# Check if initialization was attempted and failed previously in this session
init_attempted_and_failed = st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED) is False

# Initialize if never attempted OR if it failed previously (allow retry on page reload)
if not st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED, False) or init_attempted_and_failed:
    logger.info(f"Session state not initialized or previous attempt failed. Initializing Azure clients...")
    # Use a spinner for user feedback during initialization
    with st.spinner("Connecting to Azure services... Please wait."):
        # Load .env file if present (useful for local development)
        try:
            from dotenv import load_dotenv
            if load_dotenv(override=False): # override=False won't overwrite existing system env vars
                 logger.info("Loaded environment variables from .env file.")
            else:
                 logger.debug("No .env file found or it is empty.")
        except ImportError:
            logger.debug("dotenv library not found, skipping .env load.")

        # Call the initialization function from azure_clients.py
        initialization_success = initialize_clients_in_session_state()

    if not initialization_success:
        # Display a persistent error if initialization fails
        st.error("🚨 Failed to initialize connections to Azure services. Some features might be unavailable. Please check the application logs or Azure configuration.")
        # Consider stopping execution if clients are absolutely essential for all pages
        # st.stop()
    else:
         logger.info("Azure clients initialized successfully for this session.")
else:
    initialization_success = True # Already initialized successfully in this session
    logger.debug("Azure clients already initialized in this session.")

# --- Main Page Content ---

st.title("Welcome to Mirai Cook! 🍳🤖")

st.markdown("""
Your personal and intelligent AI culinary assistant.

**Explore the sections using the menu in the sidebar on the left.**
""")
# Removed the list of features from here as they are in the sidebar navigation

# --- Display Client Initialization Status ---
st.sidebar.divider() # Add a separator in the sidebar
st.sidebar.subheader("Azure Service Status")

# Define which clients to check and their user-friendly names
clients_to_check = {
    "Cosmos DB (Recipes)": SESSION_STATE_RECIPE_CONTAINER,
    "Cosmos DB (Pantry)": SESSION_STATE_PANTRY_CONTAINER,
    "Cosmos DB (Ingredients)": SESSION_STATE_INGREDIENT_CONTAINER,
    "Azure OpenAI": SESSION_STATE_OPENAI_CLIENT,
    "AI Language": SESSION_STATE_LANGUAGE_CLIENT,
    "AI Vision": SESSION_STATE_VISION_CLIENT,
    "AI Document Intelligence": SESSION_STATE_DOC_INTEL_CLIENT,
    "AI Speech": SESSION_STATE_SPEECH_CONFIG,
    "Blob Storage": SESSION_STATE_BLOB_CLIENT,
    # "AI Search": SESSION_STATE_SEARCH_CLIENT # Search client initialized later
}

# Check the global initialization flag first
init_overall_status = st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED)

if init_overall_status is None:
    st.sidebar.warning("Initializing connections...")
elif init_overall_status is False:
    st.sidebar.error("Initialization failed. Check logs.")
else:
    # Initialization was attempted and potentially partially successful
    all_ok = True
    for display_name, session_key in clients_to_check.items():
        client = st.session_state.get(session_key)
        if client:
            st.sidebar.markdown(f"- {display_name}: <span style='color:green;'>● Connected</span>", unsafe_allow_html=True)
        else:
            st.sidebar.markdown(f"- {display_name}: <span style='color:red;'>○ Failed/Unavailable</span>", unsafe_allow_html=True)
            all_ok = False
    if all_ok:
        st.sidebar.success("All core services connected.")
    else:
        st.sidebar.warning("Some services failed to connect.")


# Display a status indicator in the sidebar based on initialization success
# Moved the simple status here, below the detailed list
st.sidebar.divider()
if initialization_success:
    st.sidebar.markdown("✅ **Status:** Ready")
else:
    st.sidebar.markdown("⚠️ **Status:** Connection Issues")


# --- End of Main Page Script ---
