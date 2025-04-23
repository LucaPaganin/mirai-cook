# -*- coding: utf-8 -*-
"""
Streamlit page for importing recipes into Mirai Cook,
either from a URL or by analyzing an uploaded document/image
using Azure AI Document Intelligence.
"""

import streamlit as st
import logging
import sys
import os
from typing import List, Optional, Any

# --- Setup Project Root Path ---
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# --- Import Application Modules ---
try:
    from src.azure_clients import (
        SESSION_STATE_DOC_INTEL_CLIENT,
        SESSION_STATE_OPENAI_CLIENT,
        SESSION_STATE_CLIENTS_INITIALIZED
    )
    # Import the scraping function
    from src.recipe_scraping import scrape_recipe_metadata
    # Import AI fallback function when implemented
    # from src.ai_services import extract_recipe_from_url_ai, analyze_document_for_recipe
except ImportError as e:
    st.error(f"Error importing application modules: {e}. Check PYTHONPATH and module locations.")
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
required_clients = [SESSION_STATE_DOC_INTEL_CLIENT, SESSION_STATE_OPENAI_CLIENT]
clients_ready = True
missing_clients = []
for client_key in required_clients:
    if not st.session_state.get(client_key):
        clients_ready = False
        missing_clients.append(client_key.replace("_client", " Client"))
if not clients_ready:
    st.error(f"Error: Required Azure connections missing: {', '.join(missing_clients)}.")
    if not st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED):
         st.warning("Note: Global Azure client initialization reported issues.")
    st.stop()
else:
    doc_intel_client = st.session_state[SESSION_STATE_DOC_INTEL_CLIENT]
    openai_client = st.session_state[SESSION_STATE_OPENAI_CLIENT]
    logger.info("Successfully retrieved required Azure AI clients for Import page.")

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
        logger.info(f"URL Import requested for: {recipe_url}")
        extracted_data = None
        with st.spinner(f"Attempting to import recipe from {recipe_url}..."):
            # --- Call the scraping function ---
            scraped_data = scrape_recipe_metadata(recipe_url)

            if scraped_data:
                logger.info("Scraping successful using recipe-scrapers.")
                # Prepare data structure including the image URL
                extracted_data = {
                    "title": scraped_data.get("title"),
                    "ingredients_text": "\n".join(scraped_data.get("ingredients", [])),
                    "instructions_text": scraped_data.get("instructions_text"),
                    "image_url": scraped_data.get("image"), # <-- Include image URL
                    "source_url": recipe_url,
                    "source_type": "Imported (URL Scraper)",
                    "yields": scraped_data.get("yields"),
                    "total_time": scraped_data.get("total_time"),
                    # Add other relevant fields scraped
                }
            else:
                logger.warning(f"recipe-scrapers failed for {recipe_url}. Attempting AI fallback.")
                # --- TODO: Implement AI Fallback Logic ---
                # Remember to ask AI to describe the image if possible, or set image_url to None
                st.warning("Automatic scraping failed. AI fallback not yet implemented. Please use manual entry.") # Placeholder message

            # --- Store result and guide user ---
            if extracted_data:
                st.session_state['imported_recipe_data'] = extracted_data
                st.success("Recipe data extracted!")
                st.markdown("**Extracted Data Preview:**")
                st.text(f"Title: {extracted_data.get('title', 'N/A')}")
                # --- Display Image Preview if URL exists ---
                img_url = extracted_data.get('image_url')
                if img_url:
                    st.image(img_url, caption="Image found on page", width=200)
                # ------------------------------------------
                st.text("Ingredients (raw):")
                st.text_area("ingredients_preview", extracted_data.get('ingredients_text', 'N/A'), height=150, disabled=True)
                st.markdown("---")
                st.info("✅ Data is ready! Please go to the **Add/Edit Recipe** page to review, structure the ingredients, and save.")
            # else: Error message handled within the logic above

    elif submit_url and not recipe_url:
        st.warning("Please enter a URL.")

elif import_method == "Document/Image Analysis (Document Intelligence)":
    # --- Document Intelligence Section (remains the same for now) ---
    st.subheader("Import using Document Intelligence")
    uploaded_files = st.file_uploader(
        "Upload Recipe Image(s) or PDF:",
        type=["png", "jpg", "jpeg", "tiff", "bmp", "pdf"],
        accept_multiple_files=True,
        key="doc_intel_uploader"
    )
    available_models = {
        "Prebuilt Read (OCR Only)": "prebuilt-read",
        "Prebuilt Layout": "prebuilt-layout",
        "Prebuilt General Document": "prebuilt-document",
        "Custom Recipe Model": os.getenv("DOC_INTEL_CUSTOM_MODEL_ID", "your-custom-model-id")
    }
    if available_models["Custom Recipe Model"] == "your-custom-model-id":
        del available_models["Custom Recipe Model"]
        logger.warning("Custom Document Intelligence Model ID not configured (DOC_INTEL_CUSTOM_MODEL_ID env var).")
    model_display_names = list(available_models.keys())
    default_index = model_display_names.index("Custom Recipe Model") if "Custom Recipe Model" in model_display_names else 0
    selected_model_display_name = st.selectbox(
        "Select Document Intelligence Model:",
        options=model_display_names, index=default_index, key="doc_intel_model_select",
        help="Choose the AI model to analyze your document. 'Custom Recipe Model' is recommended if available."
    )
    selected_model_id = available_models[selected_model_display_name]
    submit_doc_intel = st.button("📄 Analyze Document/Image(s)", key="submit_doc_intel")

    if submit_doc_intel and uploaded_files:
        logger.info(f"Document Intelligence analysis requested for {len(uploaded_files)} file(s) using model: {selected_model_id}")
        with st.spinner(f"Analyzing document(s) with model '{selected_model_display_name}'..."):
            # --- TODO: Implement Document Analysis Logic ---
            # 1. Combine images to PDF if needed
            # 2. Call ai_services.analyze_document_for_recipe(...)
            # 3. Process result -> extracted_data dict (set image_url=None here)
            # 4. Store in session state: st.session_state['imported_recipe_data'] = extracted_data
            # 5. Show preview and guide user
            st.success(f"Placeholder: Successfully analyzed {len(uploaded_files)} file(s) with {selected_model_display_name}. Data ready for review (Implement logic).") # Placeholder
            # --- End TODO ---
    elif submit_doc_intel and not uploaded_files:
        st.warning("Please upload at least one file.")

st.divider()
st.markdown("After importing, please go to the **Add/Edit Recipe** page to review, structure the ingredients, and save the recipe permanently.")

