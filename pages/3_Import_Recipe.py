# -*- coding: utf-8 -*-
"""
Streamlit page for importing recipes into Mirai Cook using the RecipeImporter class.
"""

import streamlit as st
import logging
import sys
import os
from typing import List, Optional, Any, Dict, Union, IO
import pandas as pd # To display parsed ingredients preview
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
        SESSION_STATE_INGREDIENT_CONTAINER, # Needed by Importer
        SESSION_STATE_CLIENTS_INITIALIZED
    )
    # Import the new Importer class
    from src.importers import RecipeImporter
    # Import AI service functions used by Importer (though not called directly here)
    from src.ai_services.doc_intelligence import analyze_recipe_document, process_doc_intel_analyze_result
    from src.ai_services.genai import parse_ingredient_block_openai, parse_ingredient_list_openai
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

st.title("📥 Import Recipe")
st.markdown("Add recipes by providing a URL or uploading a document/image for analysis.")

# --- Check if NECESSARY Azure Clients are Initialized ---
# Importer needs DI, OpenAI, and Ingredients Container
required_clients = [
    SESSION_STATE_DOC_INTEL_CLIENT,
    SESSION_STATE_OPENAI_CLIENT,
    SESSION_STATE_INGREDIENT_CONTAINER # Added dependency
]
clients_ready = True
missing_clients = []
for client_key in required_clients:
    if not st.session_state.get(client_key):
        clients_ready = False
        missing_clients.append(client_key.replace("container", "Container Client").replace("_client", " Client"))

importer = None # Initialize importer variable
if not clients_ready:
    st.error(f"Error: Required Azure connections missing: {', '.join(missing_clients)}. Please ensure Azure services were initialized correctly.")
    logger.error(f"Import Recipe page stopped. Missing clients in session state: {', '.join(missing_clients)}")
    if not st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED):
         st.warning("Note: Global Azure client initialization reported issues.")
    st.stop() # Stop if essential clients for importer are missing
else:
    # Retrieve necessary clients from session state
    doc_intel_client = st.session_state[SESSION_STATE_DOC_INTEL_CLIENT]
    openai_client = st.session_state[SESSION_STATE_OPENAI_CLIENT]
    ingredients_container = st.session_state[SESSION_STATE_INGREDIENT_CONTAINER]
    logger.info("Successfully retrieved required Azure AI clients for Import page.")
    # --- Initialize Importer ---
    try:
        importer = RecipeImporter(
            doc_intel_client=doc_intel_client,
            openai_client=openai_client,
            ingredients_container=ingredients_container # Pass the container client
        )
        logger.info("RecipeImporter initialized.")
    except Exception as e:
        st.error(f"Failed to initialize RecipeImporter: {e}")
        logger.error(f"Error initializing RecipeImporter: {e}", exc_info=True)
        st.stop() # Stop if importer cannot be initialized


# --- Initialize session state for imported data ---
if 'imported_recipe_data' not in st.session_state:
     st.session_state['imported_recipe_data'] = None

# --- Import Method Selection ---
import_method = st.selectbox(
    "Select Import Method:",
    options=["URL", "Document/Image Analysis (Document Intelligence)"],
    index=0,
    key="import_method_select"
)

# --- Input Fields based on Selection ---
st.divider()

if import_method == "URL":
    st.subheader("Import from URL")
    recipe_url = st.text_input("Enter Recipe URL:", placeholder="https://www.giallozafferano.it/...", key="url_input")
    submit_url = st.button("🔗 Import from URL", key="submit_url")

    if submit_url and recipe_url:
        if importer: # Check if importer was initialized
            logger.info(f"URL Import requested for: {recipe_url}")
            processed_ok = False
            with st.spinner(f"Importing and parsing recipe from {recipe_url}..."):
                # --- Call Importer Method ---
                extracted_data = importer.import_from_url(recipe_url)

                if extracted_data:
                    # Store the structured data returned by the importer
                    st.session_state['imported_recipe_data'] = extracted_data
                    processed_ok = True
                else:
                     st.error(f"Could not import or process recipe data from {recipe_url}.")
                     processed_ok = False

                # --- Show Preview and Guide User if successful ---
                if processed_ok:
                    imported_result = st.session_state.get('imported_recipe_data', {})
                    st.success("Recipe data extracted and parsed!")
                    st.markdown("**Extracted Data Preview:**")
                    st.text(f"Title: {imported_result.get('title', 'N/A')}")
                    # Display other fields...
                    st.text(f"Yields: {imported_result.get('yields', 'N/A')}")
                    st.text(f"Time: {imported_result.get('total_time', 'N/A')}")
                    st.text(f"Calories (approx): {imported_result.get('calories', 'N/A')}")
                    img_url = imported_result.get('image_url')
                    if img_url:
                        st.image(img_url, caption="Image found", width=200)

                    st.text("Parsed Ingredients (Attempted):")
                    parsed_ingredients_preview = imported_result.get('parsed_ingredients', [])
                    if parsed_ingredients_preview:
                        # Display as a DataFrame for clarity
                        preview_df = pd.DataFrame(parsed_ingredients_preview)[["quantity", "unit", "name", "notes"]]
                        st.dataframe(preview_df, use_container_width=True)
                    else:
                        st.text("Could not parse ingredients.")
                    st.markdown("---")
                    st.info("✅ Data is ready! Please go to the **Add/Edit Recipe** page to review and save.")
                # else: Error messages handled within the logic above
        else:
            st.error("Recipe Importer could not be initialized. Please check configuration.")


    elif submit_url and not recipe_url:
        st.warning("Please enter a URL.")

elif import_method == "Document/Image Analysis (Document Intelligence)":
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
        "Cucina Facile V1": "cucina_facile_v1" # Your custom model example
    }
    custom_model_env_id = os.getenv("DOC_INTEL_CUSTOM_MODEL_ID")
    if custom_model_env_id:
        available_models["Custom Recipe Model (Env)"] = custom_model_env_id
    else:
        logger.warning("Optional: Set DOC_INTEL_CUSTOM_MODEL_ID env var.")

    model_display_names = list(available_models.keys())
    default_model_key = "Custom Recipe Model (Env)" if custom_model_env_id else ("Cucina Facile V1" if "Cucina Facile V1" in available_models else model_display_names[0])
    default_index = model_display_names.index(default_model_key)
    selected_model_display_name = st.selectbox(
        "Select Document Intelligence Model:", options=model_display_names, index=default_index, key="doc_intel_model_select"
    )
    selected_model_id = available_models[selected_model_display_name]

    submit_doc_intel = st.button("📄 Analyze Document/Image(s)", key="submit_doc_intel")

    if submit_doc_intel and uploaded_files:
        if importer: # Check if importer was initialized
            logger.info(f"DI analysis requested for {len(uploaded_files)} file(s) using model: {selected_model_id}")
            processed_ok = False
            with st.spinner(f"Analyzing document(s) with model '{selected_model_display_name}'..."):
                combined_doc_bytes: Optional[bytes] = None
                try:
                    # --- TODO: Implement image combination logic ---
                    if len(uploaded_files) > 1 and not uploaded_files[0].name.lower().endswith(".pdf"):
                        st.warning("Multi-image combination not implemented. Analyzing first image only.")
                    if uploaded_files:
                        uploaded_files[0].seek(0)
                        combined_doc_bytes = uploaded_files[0].read()

                    if combined_doc_bytes:
                        # --- Call Importer Method ---
                        extracted_data = importer.import_from_document(combined_doc_bytes, selected_model_id)
                        if extracted_data:
                            # Store the structured data directly
                            st.session_state['imported_recipe_data'] = extracted_data
                            processed_ok = True
                        else:
                            st.error("Failed to import or process recipe data from the document.")
                    else:
                        st.error("Failed to read uploaded file(s).")
                except Exception as e:
                    st.error(f"Error during document analysis/import: {e}")
                    logger.error(f"Error in DI import block: {e}", exc_info=True)

                # --- Show Preview and Guide User ---
                if processed_ok:
                    imported_result = st.session_state.get('imported_recipe_data', {})
                    st.success("Document analyzed and parsed!")
                    st.markdown("**Extracted Data Preview:**")
                    st.text(f"Title: {imported_result.get('title', 'N/A')}")
                    # Display other fields...
                    st.text(f"Category: {imported_result.get('category', 'N/A')}")
                    st.text(f"Difficulty: {imported_result.get('difficulty', 'N/A')}")
                    st.text(f"Time: {imported_result.get('total_time', 'N/A')}")
                    st.text(f"Yields: {imported_result.get('yields', 'N/A')}")
                    st.text(f"Drink: {imported_result.get('drink', 'N/A')}")
                    st.text(f"Calories (approx): {imported_result.get('calories', 'N/A')}")

                    st.text("Parsed Ingredients (Attempted):")
                    parsed_ingredients_preview = imported_result.get('parsed_ingredients', [])
                    if parsed_ingredients_preview:
                        preview_df = pd.DataFrame(parsed_ingredients_preview)[["quantity", "unit", "name", "notes"]]
                        st.dataframe(preview_df, use_container_width=True)
                    else:
                        st.text("Could not parse ingredients.")
                    st.markdown("---")
                    st.info("✅ Data is ready! Please go to the **Add/Edit Recipe** page to review and save.")
                # else: Error messages handled within the logic above
        else:
            st.error("Recipe Importer could not be initialized. Please check configuration.")

    elif submit_doc_intel and not uploaded_files:
        st.warning("Please upload at least one file.")

st.divider()
st.markdown("After importing, please go to the **Add/Edit Recipe** page to review, structure the ingredients, and save the recipe permanently.")

