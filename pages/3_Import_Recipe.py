# -*- coding: utf-8 -*-
"""
Streamlit page for importing recipes into Mirai Cook using the RecipeImporter class.
Refactored UI into separate functions for clarity.
"""

import streamlit as st
import logging
import sys
import os
from typing import List, Optional, Any, Dict, Union, IO
import pandas as pd
import io # For combining images

# --- Setup Project Root Path ---
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# --- Import Application Modules ---
try:
    from src.azure_clients import (
        SESSION_STATE_DOC_INTEL_CLIENT,
        SESSION_STATE_OPENAI_CLIENT,
        SESSION_STATE_INGREDIENT_CONTAINER,
        SESSION_STATE_CLIENTS_INITIALIZED
    )
    from src.importers import RecipeImporter
    # Import utilities needed by the importer or this page
    from src.utils import parse_ingredient_string # Fallback parser
except ImportError as e:
    st.error(f"Error importing application modules: {e}. Check PYTHONPATH.")
    st.stop()

# --- Configure Logging ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Page Configuration ---
try:
    st.set_page_config(page_title="Import Recipe - Mirai Cook", page_icon="📥")
except st.errors.StreamlitAPIException:
    pass # Already set

# --- Helper Functions for UI Sections ---

def render_url_import_section(importer: RecipeImporter):
    """Renders the UI section for importing a recipe from a URL."""
    st.subheader("Import from URL")
    recipe_url = st.text_input("Enter Recipe URL:", placeholder="https://www.giallozafferano.it/...", key="url_input")
    submit_url = st.button("🔗 Import from URL", key="submit_url")

    if submit_url and recipe_url:
        if importer:
            logger.info(f"URL Import requested for: {recipe_url}")
            with st.spinner(f"Importing and parsing recipe from {recipe_url}..."):
                extracted_data = importer.import_from_url(recipe_url)
                if extracted_data:
                    # Store result in session state for preview and next page
                    st.session_state['imported_recipe_data'] = extracted_data
                    st.success("Recipe data extracted! See preview below.")
                    # Rerun to show preview immediately
                    st.rerun()
                else:
                     st.error(f"Could not import or process recipe data from {recipe_url}.")
        else:
            st.error("Recipe Importer not available.")
    elif submit_url and not recipe_url:
        st.warning("Please enter a URL.")

def render_doc_intel_section(importer: RecipeImporter):
    """Renders the UI section for importing using Document Intelligence."""
    st.subheader("Import using Document Intelligence")
    uploaded_files = st.file_uploader(
        "Upload Recipe Image(s) or PDF:",
        type=["png", "jpg", "jpeg", "tiff", "bmp", "pdf"],
        accept_multiple_files=True,
        key="doc_intel_uploader"
    )

    # Get available model IDs
    available_models = {
        "Prebuilt Read (OCR Only)": "prebuilt-read",
        "Prebuilt Layout": "prebuilt-layout",
        "Prebuilt General Document": "prebuilt-document",
        "Cucina Facile V1": "cucina_facile_v1" # Example custom model
    }
    custom_model_env_id = os.getenv("DOC_INTEL_CUSTOM_MODEL_ID")
    if custom_model_env_id: available_models["Custom Recipe Model (Env)"] = custom_model_env_id
    else: logger.debug("Optional: Set DOC_INTEL_CUSTOM_MODEL_ID env var.") # Changed to debug

    model_display_names = list(available_models.keys())
    default_model_key = "Custom Recipe Model (Env)" if custom_model_env_id else ("Cucina Facile V1" if "Cucina Facile V1" in available_models else model_display_names[0])
    try:
        default_index = model_display_names.index(default_model_key)
    except ValueError:
        default_index = 0 # Fallback to first model if default not found
    selected_model_display_name = st.selectbox(
        "Select Document Intelligence Model:", options=model_display_names, index=default_index, key="doc_intel_model_select"
    )
    selected_model_id = available_models[selected_model_display_name]

    submit_doc_intel = st.button("📄 Analyze Document/Image(s)", key="submit_doc_intel")

    if submit_doc_intel and uploaded_files:
        if importer:
            logger.info(f"DI analysis requested for {len(uploaded_files)} file(s) using model: {selected_model_id}")
            with st.spinner(f"Analyzing document(s) with model '{selected_model_display_name}'..."):
                combined_doc_bytes: Optional[bytes] = None
                try:
                    # --- TODO: Implement image combination logic ---
                    if len(uploaded_files) > 1 and not uploaded_files[0].name.lower().endswith(".pdf"): st.warning("Multi-image combination not implemented. Analyzing first image only.")
                    if uploaded_files: uploaded_files[0].seek(0); combined_doc_bytes = uploaded_files[0].read()

                    if combined_doc_bytes:
                        # --- Call Importer Method ---
                        extracted_data = importer.import_from_document(combined_doc_bytes, selected_model_id)
                        if extracted_data:
                            # Store the structured data directly
                            st.session_state['imported_recipe_data'] = extracted_data
                            st.success("Document analyzed! See preview below.")
                            # Rerun to show preview immediately
                            st.rerun()
                        else:
                            st.error("Failed to import or process recipe data from the document.")
                    else: st.error("Failed to read uploaded file(s).")
                except Exception as e: st.error(f"Error during document analysis/import: {e}"); logger.error(f"Error in DI import block: {e}", exc_info=True)
        else:
             st.error("Recipe Importer not available.")

    elif submit_doc_intel and not uploaded_files:
        st.warning("Please upload at least one file.")


def render_preview_section():
    """Renders the preview section if imported data exists in session state."""
    imported_result = st.session_state.get('imported_recipe_data')

    if imported_result:
        st.divider()
        st.subheader("Imported Data Preview")
        st.success("Recipe data extracted and parsed!")
        st.markdown("**Review the data below. If correct, proceed to 'Add/Edit Recipe' to finalize and save.**")

        st.text(f"Title: {imported_result.get('title', 'N/A')}")
        # Display other extracted fields
        col1, col2, col3 = st.columns(3)
        with col1: 
            st.text(f"Yields: {imported_result.get('yields', 'N/A')}")
        with col2: 
            st.text(f"Time: {imported_result.get('total_time', 'N/A')}")
        with col3: 
            st.text(f"Calories (approx): {imported_result.get('calories', 'N/A')}")

        col4, col5, col6 = st.columns(3)
        with col4: 
            st.text(f"Category: {imported_result.get('category', 'N/A')}")
        with col5: 
            st.text(f"Difficulty: {imported_result.get('difficulty', 'N/A')}")
        with col6: 
            st.text(f"Drink: {imported_result.get('drink', 'N/A')}")

        img_url = imported_result.get('image_url')
        if img_url:
            st.image(img_url, caption="Image found", width=200)

        st.text("Parsed Ingredients (Attempted):")
        parsed_ingredients_preview = imported_result.get('parsed_ingredients', [])
        if parsed_ingredients_preview:
            # Display as a DataFrame for clarity
            preview_df = pd.DataFrame(parsed_ingredients_preview)[["quantity", "unit", "name", "notes"]]
            # Use st.dataframe for better table rendering
            st.dataframe(preview_df, use_container_width=True, hide_index=True)
        else:
            st.text("Could not parse ingredients.")

        # Button/Link to navigate (optional, user can also use sidebar)
        if st.button("Go to Add/Edit Page to Save"):
           st.switch_page("pages/2_Add_Edit.py") # Requires Streamlit > 1.28

        st.info("✅ Data is ready! Go to the **Add/Edit Recipe** page to review, structure ingredients, and save permanently.")


# --- Main Page Logic ---

# Initialize session state key if it doesn't exist
if 'imported_recipe_data' not in st.session_state:
     st.session_state['imported_recipe_data'] = None

# Check Azure client initialization status
if not st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED):
    st.warning("Azure services are not connected. Please go to the main page first or check configuration.")
    st.stop()

# Retrieve necessary clients and initialize importer
importer = None
try:
    doc_intel_client = st.session_state[SESSION_STATE_DOC_INTEL_CLIENT]
    openai_client = st.session_state[SESSION_STATE_OPENAI_CLIENT]
    ingredients_container = st.session_state[SESSION_STATE_INGREDIENT_CONTAINER]
    importer = RecipeImporter(
        doc_intel_client=doc_intel_client,
        openai_client=openai_client,
        ingredients_container=ingredients_container
    )
    logger.info("RecipeImporter initialized for Import page.")
except KeyError as e:
     st.error(f"Error: Required client '{e}' not found in session state. Initialization might have failed.")
     st.stop()
except Exception as e:
     st.error(f"Failed to initialize RecipeImporter: {e}")
     logger.error(f"Error initializing RecipeImporter: {e}", exc_info=True)
     st.stop()


# --- UI Rendering ---
import_method = st.selectbox(
    "Select Import Method:",
    options=["URL", "Document/Image Analysis (Document Intelligence)"],
    index=0,
    key="import_method_select"
)
st.divider()

# Render the appropriate input section based on selection
if import_method == "URL":
    render_url_import_section(importer)
elif import_method == "Document/Image Analysis (Document Intelligence)":
    render_doc_intel_section(importer)

# Always render the preview section if data exists
render_preview_section()

