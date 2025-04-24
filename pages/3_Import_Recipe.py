# -*- coding: utf-8 -*-
"""
Streamlit page for importing recipes into Mirai Cook.
Separates Document Intelligence result processing from AI Language ingredient extraction.
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
        SESSION_STATE_LANGUAGE_CLIENT, # Language client key needed here
        SESSION_STATE_CLIENTS_INITIALIZED
    )
    from src.recipe_scraping import scrape_recipe_metadata
    from src.utils import parse_ingredient_string
    # Import AI service functions
    from src.ai_services import (
        analyze_recipe_document,
        process_doc_intel_analyze_result, # Assumes this NO LONGER calls extract_ingredients
        extract_recipe_ingredients # Will be called directly here
        # extract_recipe_from_url_ai # For AI fallback later
    )
    # Import image combination utility if implemented
    # from src.utils import combine_images_to_pdf
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
required_clients = [
    SESSION_STATE_DOC_INTEL_CLIENT,
    SESSION_STATE_OPENAI_CLIENT,
    SESSION_STATE_LANGUAGE_CLIENT # Required
]
clients_ready = True
missing_clients = []
for client_key in required_clients:
    if not st.session_state.get(client_key):
        clients_ready = False
        missing_clients.append(client_key.replace("_client", " Client").replace("_config", " Config"))

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
    language_client = st.session_state[SESSION_STATE_LANGUAGE_CLIENT] # Retrieve Language client
    logger.info("Successfully retrieved required Azure AI clients for Import page.")


# --- Initialize session state for imported data ---
if 'imported_recipe_data' not in st.session_state:
     st.session_state['imported_recipe_data'] = None

# --- Helper Function to Parse and Store ---
def process_and_store_extracted_data(extracted_data: Dict[str, Any]):
    """
    Processes ingredient data (raw text/list OR pre-parsed list)
    and stores structured data in session state.
    """
    if not extracted_data:
        logger.error("process_and_store_extracted_data called with empty data.")
        return False

    parsed_ingredients_list = []
    # Check if 'parsed_ingredients' key already exists (from direct NER call)
    if 'parsed_ingredients' in extracted_data and isinstance(extracted_data['parsed_ingredients'], list):
        logger.info(f"Using {len(extracted_data['parsed_ingredients'])} pre-parsed ingredients.")
        parsed_ingredients_list = extracted_data['parsed_ingredients'] # Assume it's already in the correct format
    else:
        # Fallback to parsing raw strings if 'parsed_ingredients' is not present
        raw_ingredients_list = []
        ingredients_input = extracted_data.get('ingredients') # From scraper list or DI raw text block
        if isinstance(ingredients_input, list): # List of strings from scraper
             raw_ingredients_list = ingredients_input
             if 'ingredients_text' not in extracted_data or not extracted_data['ingredients_text']:
                 extracted_data['ingredients_text'] = "\n".join(raw_ingredients_list)
        elif isinstance(ingredients_input, str): # Text block from DI/AI
             raw_ingredients_list = ingredients_input.strip().split('\n')
             extracted_data['ingredients_text'] = ingredients_input # Ensure text version exists

        if raw_ingredients_list:
            logger.info(f"Parsing {len(raw_ingredients_list)} raw ingredient lines using utils.parse_ingredient_string...")
            for line in raw_ingredients_list:
                if line.strip():
                    parsed = parse_ingredient_string(line.strip())
                    parsed_ingredients_list.append(parsed)
            logger.info(f"Generated {len(parsed_ingredients_list)} parsed ingredient structures via utils.")
            extracted_data['parsed_ingredients'] = parsed_ingredients_list # Add parsed list
        else:
            logger.warning("No raw ingredient data found to parse.")
            extracted_data['parsed_ingredients'] = [] # Ensure key exists

    # Store the complete data in session state
    st.session_state['imported_recipe_data'] = extracted_data
    logger.debug(f"Stored imported_recipe_data in session state: {st.session_state['imported_recipe_data']}")
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
                # Prepare data structure - 'ingredients' key holds list of strings here
                final_extracted_data = {
                    "title": scraped_data.get("title"),
                    "ingredients": scraped_data.get("ingredients", []), # Pass raw list
                    "instructions_text": scraped_data.get("instructions_text"),
                    "image_url": scraped_data.get("image"),
                    "source_url": recipe_url,
                    "source_type": "Imported (URL Scraper)",
                    "yields": scraped_data.get("yields"),
                    "total_time": scraped_data.get("total_time"),
                    "category": scraped_data.get("category"),
                    "difficulty": scraped_data.get("difficulty"),
                }
            else:
                logger.warning(f"recipe-scrapers failed for {recipe_url}. Attempting AI fallback.")
                # --- TODO: Implement AI Fallback Logic ---
                st.warning("Automatic scraping failed. AI fallback not yet implemented.")

            # 2. Process (parse ingredients using utils) and Store
            if final_extracted_data:
                # This will call parse_ingredient_string on the raw list/text
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

                st.text("Parsed Ingredients (Attempted via Utils):")
                parsed_ingredients_preview = imported_result.get('parsed_ingredients', [])
                if parsed_ingredients_preview:
                    preview_df = pd.DataFrame(parsed_ingredients_preview)[["quantity", "unit", "name", "notes"]]
                    st.dataframe(preview_df, use_container_width=True)
                else:
                    st.text("Could not parse ingredients from text.")

                st.markdown("---")
                st.info("✅ Data is ready! Please go to the **Add/Edit Recipe** page to review and save.")

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
    if custom_model_env_id: available_models["Custom Recipe Model (Env)"] = custom_model_env_id
    else: logger.warning("Optional: Set DOC_INTEL_CUSTOM_MODEL_ID env var.")

    model_display_names = list(available_models.keys())
    default_model_key = "Custom Recipe Model (Env)" if custom_model_env_id else ("Cucina Facile V1" if "Cucina Facile V1" in available_models else model_display_names[0])
    default_index = model_display_names.index(default_model_key)
    selected_model_display_name = st.selectbox(
        "Select Document Intelligence Model:", options=model_display_names, index=default_index, key="doc_intel_model_select"
    )
    selected_model_id = available_models[selected_model_display_name]

    submit_doc_intel = st.button("📄 Analyze Document/Image(s)", key="submit_doc_intel")

    if submit_doc_intel and uploaded_files:
        logger.info(f"Document Intelligence analysis requested for {len(uploaded_files)} file(s) using model: {selected_model_id}")
        processed_ok = False
        with st.spinner(f"Analyzing document(s) with model '{selected_model_display_name}'..."):
            # --- Document Analysis Logic ---
            combined_doc_bytes: Optional[bytes] = None
            try:
                # 1. Combine images to PDF if needed (Placeholder)
                # TODO: Implement image combination logic using src.utils.combine_images_to_pdf
                if len(uploaded_files) > 1 and not uploaded_files[0].name.lower().endswith(".pdf"):
                    st.warning("Multi-image combination not yet implemented. Analyzing only the first image.")
                    uploaded_files[0].seek(0); combined_doc_bytes = uploaded_files[0].read()
                elif uploaded_files:
                    uploaded_files[0].seek(0); combined_doc_bytes = uploaded_files[0].read()

                if combined_doc_bytes:
                    # 2. Call ai_services.analyze_recipe_document
                    analyze_result = analyze_recipe_document(doc_intel_client, selected_model_id, combined_doc_bytes)

                    if analyze_result and analyze_result.documents:
                        # 3. Process AnalyzeResult using the updated function (which NO LONGER calls NER)
                        # It should return the raw ingredient text block if found.
                        analysis_output = process_doc_intel_analyze_result(
                            analyze_result.documents[0].fields, # Pass the fields dictionary
                            selected_model_id
                            # No longer pass language_client here
                        )

                        # 4. Prepare extracted_data dictionary
                        if analysis_output and analysis_output.get('title'):
                             extracted_data = {
                                 'title': analysis_output.get('title'),
                                 # Store the RAW ingredient text block
                                 'ingredients_text': analysis_output.get('ingredients'),
                                 'instructions_text': analysis_output.get('instructions'),
                                 'total_time': analysis_output.get('total_time'),
                                 'yields': analysis_output.get('yields'),
                                 'difficulty': analysis_output.get('difficulty'),
                                 'source_type': 'Digitalizzata',
                                 'image_url': None,
                                 'drink': analysis_output.get('drink'),
                                 'category': analysis_output.get('category'),
                             }

                             # --- NEW: Call AI Language NER Separately ---
                             ingredients_text_block = extracted_data.get('ingredients_text')
                             parsed_ingredients_ner = None
                             if ingredients_text_block:
                                 logger.info("Attempting ingredient extraction using AI Language NER...")
                                 with st.spinner("Extracting structured ingredients..."):
                                     parsed_ingredients_ner = extract_recipe_ingredients(language_client, ingredients_text_block)
                                 if parsed_ingredients_ner:
                                     logger.info(f"NER extracted {len(parsed_ingredients_ner)} potential ingredient structures.")
                                     # Add the NER result directly to the data to be stored
                                     extracted_data['ingredients'] = parsed_ingredients_ner # Use 'ingredients' key for structured list
                                 else:
                                     logger.warning("AI Language NER did not return structured ingredients.")
                                     # Keep ingredients_text for fallback parsing in process_and_store
                             else:
                                 logger.warning("No ingredient text block extracted by Document Intelligence to send to NER.")
                             # --- END NEW ---

                             # 5. Process and store (will use structured 'ingredients' if NER succeeded)
                             processed_ok = process_and_store_extracted_data(extracted_data)
                        else:
                            st.error("Could not extract necessary fields (like title) from the document analysis result.")
                            logger.error(f"Failed to process DI result fields: {analyze_result.documents[0].fields if analyze_result.documents else 'No documents'}")
                    else:
                         st.error("Document analysis failed or returned no results.")
                         logger.error(f"analyze_recipe_document returned: {analyze_result}")
                else:
                    st.error("Failed to read uploaded file(s).")

            except Exception as e:
                 st.error(f"An error occurred during document analysis: {e}")
                 logger.error(f"Error in DI analysis block: {e}", exc_info=True)
            # --- End Document Analysis Logic ---

            # --- Show Preview and Guide User if successful ---
            if processed_ok:
                imported_result = st.session_state.get('imported_recipe_data', {})
                st.success("Document analyzed and parsed!")
                st.markdown("**Extracted Data Preview:**")
                st.text(f"Title: {imported_result.get('title', 'N/A')}")
                # Display other extracted fields
                st.text(f"Category: {imported_result.get('category', 'N/A')}")
                st.text(f"Difficulty: {imported_result.get('difficulty', 'N/A')}")
                st.text(f"Time: {imported_result.get('total_time', 'N/A')}")
                st.text(f"Yields: {imported_result.get('yields', 'N/A')}")
                st.text(f"Drink: {imported_result.get('drink', 'N/A')}")

                st.text("Parsed Ingredients (Attempted via NER/Utils):")
                parsed_ingredients_preview = imported_result.get('parsed_ingredients', [])
                if parsed_ingredients_preview:
                    preview_df = pd.DataFrame(parsed_ingredients_preview)[["quantity", "unit", "name", "notes"]]
                    st.dataframe(preview_df, use_container_width=True)
                else:
                    st.text("Could not parse ingredients from text.")
                st.markdown("---")
                st.info("✅ Data is ready! Please go to the **Add/Edit Recipe** page to review and save.")
            # else: Error messages handled within the logic

    elif submit_doc_intel and not uploaded_files:
        st.warning("Please upload at least one file.")

st.divider()
st.markdown("After importing, please go to the **Add/Edit Recipe** page to review, structure the ingredients, and save the recipe permanently.")

