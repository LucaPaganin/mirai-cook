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
# Assumes mirai_cook.py is in the root project folder alongside 'src' and 'pages'
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '.'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# --- Import Initialization Function and Keys ---
try:
    # Import the function and the session state key
    from src.azure_clients import (
        initialize_clients_in_session_state,
        SESSION_STATE_CLIENTS_INITIALIZED, # Key for the overall status flag
        # Import keys for individual clients to check status
        SESSION_STATE_COSMOS_CLIENT,
        SESSION_STATE_RECIPE_CONTAINER,
        SESSION_STATE_PANTRY_CONTAINER,
        SESSION_STATE_INGREDIENT_CONTAINER,
        SESSION_STATE_OPENAI_CLIENT,
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
# Use the correct key constant here
init_status = st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED) # Can be True, False, or None

# Initialize if never attempted (None) OR if it failed previously (False)
if init_status is None or init_status is False:
    logger.info(f"Session state not initialized ({init_status=}). Initializing Azure clients...")
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

# --- Display Client Initialization Status ---
st.sidebar.divider() # Add a separator in the sidebar
st.sidebar.subheader("Azure Service Status")

# Define which clients to check and their user-friendly names
clients_to_check = {
    "Cosmos DB (Recipes)": SESSION_STATE_RECIPE_CONTAINER,
    "Cosmos DB (Pantry)": SESSION_STATE_PANTRY_CONTAINER,
    "Cosmos DB (Ingredients)": SESSION_STATE_INGREDIENT_CONTAINER,
    "Azure OpenAI": SESSION_STATE_OPENAI_CLIENT,
    "AI Vision": SESSION_STATE_VISION_CLIENT,
    "AI Document Intelligence": SESSION_STATE_DOC_INTEL_CLIENT,
    "AI Speech": SESSION_STATE_SPEECH_CONFIG,
    "Blob Storage": SESSION_STATE_BLOB_CLIENT,
    "AI Search": SESSION_STATE_SEARCH_CLIENT # Check Search client status too
}

# Check the global initialization flag first using the correct key
init_overall_status = st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED)

if init_overall_status is None:
    st.sidebar.warning("Initializing connections...")
elif init_overall_status is False:
    st.sidebar.error("Initialization failed. Check logs.")
    # Optionally list individual statuses even on overall failure
    for display_name, session_key in clients_to_check.items():
        client = st.session_state.get(session_key)
        if not client:
             # Use slightly different icon for failed state vs merely unavailable
             st.sidebar.markdown(f"- {display_name}: <span style='color:red;'>○ Failed</span>", unsafe_allow_html=True)

else:
    # Initialization was attempted and potentially partially successful
    all_ok = True
    for display_name, session_key in clients_to_check.items():
        client = st.session_state.get(session_key)
        if client:
            st.sidebar.markdown(f"- {display_name}: <span style='color:green;'>● Connected</span>", unsafe_allow_html=True)
        else:
            # This case might happen if initialization succeeded overall but one optional client failed (like Search)
            st.sidebar.markdown(f"- {display_name}: <span style='color:orange;'>○ Unavailable</span>", unsafe_allow_html=True)
            # Decide if missing non-critical clients should affect overall 'all_ok' status
            # if session_key == SESSION_STATE_SEARCH_CLIENT: # Example: Don't fail overall for Search
            #    pass
            # else:
            #    all_ok = False
            all_ok = False # For now, mark not all ok if anything is missing

    if all_ok:
        st.sidebar.success("All core services connected.")
    else:
        st.sidebar.warning("Some services unavailable.")


# Display a simple status indicator based on the overall success flag
st.sidebar.divider()
if initialization_success: # Use the variable determined at the start of the script run
    st.sidebar.markdown("✅ **Status:** Ready")
else:
    st.sidebar.markdown("⚠️ **Status:** Connection Issues")


# --- End of Main Page Script ---
