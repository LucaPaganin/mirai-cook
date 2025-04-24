# -*- coding: utf-8 -*-
"""
Streamlit page for importing recipes into Mirai Cook,
either from a URL or by analyzing an uploaded document/image
using Azure AI Document Intelligence.
Includes tentative parsing of ingredients after data extraction.
"""

import streamlit as st
import logging
import sys
import os
from typing import List, Optional, Any, Dict, Union, IO
import pandas as pd # To display parsed ingredients preview

# --- Setup Project Root Path ---
# Allows importing from the 'src' module
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
    # Import the ingredient parsing utility
    from src.utils import parse_ingredient_string, process_doc_intel_analyze_result
    # Import AI functions when implemented
    from src.ai_services import analyze_recipe_document
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
# For URL import, we might need OpenAI as a fallback
# For Doc Intel, we need the specific client
required_clients = [SESSION_STATE_DOC_INTEL_CLIENT, SESSION_STATE_OPENAI_CLIENT]
clients_ready = True
missing_clients = []
for client_key in required_clients:
    if not st.session_state.get(client_key):
        # We might allow the page to load even if one client is missing,
        # but disable the corresponding import method.
        # For now, let's require both for simplicity in the boilerplate.
        clients_ready = False
        missing_clients.append(client_key.replace("_client", " Client"))

if not clients_ready:
    st.error(f"Error: Required Azure connections missing: {', '.join(missing_clients)}. Please ensure Azure services were initialized correctly.")
    logger.error(f"Import Recipe page stopped. Missing clients in session state: {', '.join(missing_clients)}")
    if not st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED):
         st.warning("Note: Global Azure client initialization reported issues.")
    st.stop()
else:
    # Retrieve necessary clients from session state
    doc_intel_client = st.session_state[SESSION_STATE_DOC_INTEL_CLIENT]
    openai_client = st.session_state[SESSION_STATE_OPENAI_CLIENT]
    logger.info("Successfully retrieved required Azure AI clients for Import page.")


# --- Initialize session state for imported data ---
# Clear previous import data if navigating back or starting fresh
# This check ensures it's only cleared if not already set by this page run
if 'imported_recipe_data' not in st.session_state:
     st.session_state['imported_recipe_data'] = None

# --- Helper Function to Parse and Store ---
def process_and_store_extracted_data(extracted_data: Dict[str, Any]):
    """Parses raw ingredient text and stores structured data in session state."""
    if not extracted_data:
        return False

    parsed_ingredients_list = []
    # Prioritize 'ingredients' list from scraper, fallback to 'ingredients_text'
    raw_ingredients_list = extracted_data.get('ingredients', []) # List[str] from scraper
    raw_ingredients_text = extracted_data.get('ingredients_text', '') # String from AI/DI or scraper fallback

    source_list = []
    if raw_ingredients_list: # Prefer list from scraper if available
         source_list = raw_ingredients_list
         # Ensure text version exists for consistency if needed later
         if 'ingredients_text' not in extracted_data or not extracted_data['ingredients_text']:
             extracted_data['ingredients_text'] = "\n".join(raw_ingredients_list)
    elif raw_ingredients_text:
         source_list = raw_ingredients_text.strip().split('\n')

    if source_list:
        logger.info(f"Parsing {len(source_list)} raw ingredient lines...")
        for line in source_list:
            if line.strip():
                # *** CALLING THE PARSER ***
                parsed = parse_ingredient_string(line.strip())
                # Store the parsed dictionary directly
                parsed_ingredients_list.append(parsed)
        logger.info(f"Generated {len(parsed_ingredients_list)} parsed ingredient structures.")
    else:
        logger.warning("No raw ingredient data found to parse.")

    # *** ADDING PARSED DATA TO DICTIONARY ***
    extracted_data['parsed_ingredients'] = parsed_ingredients_list
    # *** STORING COMPLETE DATA IN SESSION STATE ***
    st.session_state['imported_recipe_data'] = extracted_data
    return True


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
        processed_ok = False
        with st.spinner(f"Attempting to import recipe from {recipe_url}..."):
            # 1. Call the scraping function
            scraped_data = scrape_recipe_metadata(recipe_url)
            final_extracted_data = None

            if scraped_data:
                logger.info("Scraping successful using recipe-scrapers.")
                # Prepare data structure
                final_extracted_data = {
                    "title": scraped_data.get("title"),
                    "ingredients": scraped_data.get("ingredients", []), # Keep raw list
                    "instructions_text": scraped_data.get("instructions_text"),
                    "image_url": scraped_data.get("image"),
                    "source_url": recipe_url,
                    "source_type": "Imported (URL Scraper)",
                    "yields": scraped_data.get("yields"), # Pass yields
                    "total_time": scraped_data.get("total_time"), # Pass total_time
                }
            else:
                logger.warning(f"recipe-scrapers failed for {recipe_url}. Attempting AI fallback.")
                # --- TODO: Implement AI Fallback Logic ---
                # Remember to try and extract title, ingredients_text, instructions_text, yields, total_time
                st.warning("Automatic scraping failed. AI fallback not yet implemented.")

            # 2. Process and Store if data was extracted
            if final_extracted_data:
                processed_ok = process_and_store_extracted_data(final_extracted_data)
            else:
                 st.error(f"Could not extract recipe data from {recipe_url}.")

            # 3. Show Preview and Guide User if successful
            if processed_ok:
                imported_result = st.session_state.get('imported_recipe_data', {})
                st.success("Recipe data extracted and parsed!")
                st.markdown("**Extracted Data Preview:**")
                st.text(f"Title: {imported_result.get('title', 'N/A')}")
                img_url = imported_result.get('image_url')
                if img_url: st.image(img_url, caption="Image found", width=200)

                st.text("Parsed Ingredients (Attempted):")
                parsed_ingredients_preview = imported_result.get('parsed_ingredients', [])
                if parsed_ingredients_preview:
                    # Display as a DataFrame for clarity
                    preview_df = pd.DataFrame(parsed_ingredients_preview)[["quantity", "unit", "name", "notes"]]
                    st.dataframe(preview_df, use_container_width=True)
                else:
                    st.text("Could not parse ingredients from text.")

                st.markdown("---")
                st.info("✅ Data is ready! Please go to the **Add/Edit Recipe** page to review, structure ingredients, and save.")
            # else: Error messages handled within the logic

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
        "Cucina Facile": "cucina_facile_v1"
    }
    model_display_names = list(available_models.keys())
    default_index = model_display_names.index("Custom Recipe Model") if "Custom Recipe Model" in model_display_names else 0
    selected_model_display_name = st.selectbox(
        "Select Document Intelligence Model:", options=model_display_names, index=default_index, key="doc_intel_model_select"
    )
    selected_model_id = available_models[selected_model_display_name]

    submit_doc_intel = st.button("📄 Analyze Document/Image(s)", key="submit_doc_intel")

    if submit_doc_intel and uploaded_files:
        logger.info(f"Document Intelligence analysis requested for {len(uploaded_files)} file(s) using model: {selected_model_id}")
        processed_ok = False
        with st.spinner(f"Analyzing document(s) with model '{selected_model_display_name}'..."):
            # --- TODO: Implement Document Analysis Logic ---
            # 1. Obtain the bytes of the uploaded file(s)
            # For now, only pass the first file's bytes (extend to combine if needed)
            if not uploaded_files:
                st.warning("Please upload at least one file before analyzing.")
                combined_doc_bytes = None
            else:
                # If multiple files, you could combine them into a PDF (not implemented here)
                # For now, just use the first file
                uploaded_file = uploaded_files[0]
                uploaded_file.seek(0)
                combined_doc_bytes = uploaded_file.read()
                logger.info(f"Read {len(combined_doc_bytes)} bytes from uploaded file '{uploaded_file.name}'.")
                # 2. Call ai_services.analyze_recipe_document(doc_intel_client, selected_model_id, combined_doc_bytes) -> returns AnalyzeResult
                result = analyze_recipe_document(doc_intel_client, selected_model_id, combined_doc_bytes)
                # 3. Process AnalyzeResult to get title, ingredients_text, instructions_text
                analysis_output = process_doc_intel_analyze_result(result, selected_model_id)
                # 4. Prepare extracted_data dictionary
                extracted_data = {
                    'title': analysis_output.get('title'),
                    'ingredients_text': analysis_output.get('ingredients_block'),
                    'instructions_text': analysis_output.get('instructions_block'),
                    'source_type': 'Digitalizzata',
                    'image_url': None # No image URL from document analysis
                    # Try to extract yields/time too if using custom model
                }
                # 5. Process and store if data extracted
                if extracted_data.get('title'): # Basic check
                    processed_ok = process_and_store_extracted_data(extracted_data)
                else:
                    st.error("Could not extract necessary fields from the document.")

            st.success(f"Placeholder: Successfully analyzed {len(uploaded_files)} file(s). Data ready for review (Implement logic).") # Placeholder
            # --- End TODO ---

            # --- Show Preview and Guide User if successful ---
            if processed_ok:
                imported_result = st.session_state.get('imported_recipe_data', {})
                st.success("Document analyzed and parsed!")
                st.markdown("**Extracted Data Preview:**")
                st.text(f"Title: {imported_result.get('title', 'N/A')}")
                st.text("Parsed Ingredients (Attempted):")
                parsed_ingredients_preview = imported_result.get('parsed_ingredients', [])
                if parsed_ingredients_preview:
                    preview_df = pd.DataFrame(parsed_ingredients_preview)[["quantity", "unit", "name", "notes"]]
                    st.dataframe(preview_df, use_container_width=True)
                else:
                    st.text("Could not parse ingredients from text.")
                st.markdown("---")
                st.info("✅ Data is ready! Please go to the **Add/Edit Recipe** page to review, structure ingredients, and save.")
            # else: Error messages handled within the logic

    elif submit_doc_intel and not uploaded_files:
        st.warning("Please upload at least one file.")

st.divider()
st.markdown("After importing, please go to the **Add/Edit Recipe** page to review, structure the ingredients, and save the recipe permanently.")

