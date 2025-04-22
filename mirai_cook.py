# -*- coding: utf-8 -*-
"""
Main entry point for the Mirai Cook Streamlit application.
This script sets up the page configuration, initializes Azure clients
via session state, and displays the home/welcome page.
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

# --- Import Initialization Function ---
try:
    # Import the function and the session state key
    from src.azure_clients import initialize_clients_in_session_state, SESSION_STATE_CLIENTS_INITIALIZED
except ImportError as e:
    # Use st.exception to show the error directly in the app during development
    st.exception(f"Fatal Error: Could not import 'initialize_clients_in_session_state' from src.azure_clients. Check PYTHONPATH and file location. Error: {e}")
    # Stop the app if core initialization is missing
    st.stop()

# --- Configure Logging ---
# Basic config here, might be refined later
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)
# Reduce Azure SDK verbosity
logging.getLogger("azure.core.pipeline.policies.http_logging_policy").setLevel(logging.WARNING)
logging.getLogger("azure.identity._internal.managed_identity_client").setLevel(logging.WARNING)


# --- Page Configuration (Must be the first Streamlit command) ---
# Use try-except in case it's already set by another page (though less likely for the main script)
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

**Explore the sections using the menu in the sidebar on the left:**

* **Recipe Book:** Browse, search, and view your saved recipes.
* **Add/Edit Recipe:** Manually enter new recipes or modify existing ones.
* **Import Recipe:** Add recipes by digitizing from images/PDFs or importing from URLs.
* **Pantry Management:** Keep track of the ingredients you have available.
* **Ingredient Management:** View and manage the master list of ingredients known to the app.
* **AI Suggestions:** Ask the AI what to cook based on your cookbook and pantry, or have it generate entirely new recipes.
* **Advanced Search:** Use the power of Azure AI Search to find recipes in your database.

*(This is the main page. Specific logic for each section is in the corresponding files within the `pages/` folder.)*
""")

# Display a status indicator in the sidebar based on initialization success
if initialization_success:
    st.sidebar.success("Azure services connected. Select a page.")
else:
    st.sidebar.error("Azure connection failed. App may be limited.")

# --- End of Main Page Script ---
