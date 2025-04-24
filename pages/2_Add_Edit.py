# -*- coding: utf-8 -*-
"""
Streamlit page for manually adding or editing recipes in Mirai Cook.
Handles pre-population of form fields if data is imported from page 3,
using the pre-parsed ingredient data and other extracted fields.
Corrected state persistence for default values across page navigations.
"""

import streamlit as st
import pandas as pd
from datetime import datetime, timezone
import logging
import sys
import os
from typing import List, Optional

# --- Setup Project Root Path ---
# Allows importing from the 'src' module
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# --- Import Application Modules ---
try:
    # Recipe model now uses 'category' instead of 'portata_category' and 'total_time_minutes'
    from src.models import Recipe, IngredientItem, IngredientEntity, sanitize_for_id
    from src.persistence import (
       save_recipe,
       get_ingredient_entity,
       find_similar_ingredient_display_names,
       upsert_ingredient_entity
    )
    from src.azure_clients import (
        SESSION_STATE_RECIPE_CONTAINER,
        SESSION_STATE_INGREDIENT_CONTAINER,
        SESSION_STATE_CLIENTS_INITIALIZED,
        # SESSION_STATE_BLOB_CLIENT # Needed for uploading NEW images
    )
    # Import the parser utility
    from src.utils import parse_ingredient_string, parse_servings # Import helpers
except ImportError as e:
    st.error(f"Error importing application modules: {e}. Check PYTHONPATH.")
    st.stop()

# --- Configure Logging ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Page Configuration ---
try:
    st.set_page_config(page_title="Add/Edit Recipe - Mirai Cook", page_icon="✍️")
except st.errors.StreamlitAPIException: pass

st.title("✍️ Add / Edit Recipe")

# --- Check if NECESSARY Azure Clients are Initialized ---
required_clients = [SESSION_STATE_RECIPE_CONTAINER, SESSION_STATE_INGREDIENT_CONTAINER]
clients_ready = True
missing_clients = []
for client_key in required_clients:
    if not st.session_state.get(client_key):
        clients_ready = False; missing_clients.append(client_key.replace("container", "Container Client"))
if not clients_ready:
    st.error(f"Error: Required Azure connections missing: {', '.join(missing_clients)}.")
    if not st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED): st.warning("Global Azure init reported issues.")
    st.stop()
else:
    recipe_container = st.session_state[SESSION_STATE_RECIPE_CONTAINER]
    ingredients_container = st.session_state[SESSION_STATE_INGREDIENT_CONTAINER]
    # blob_client = st.session_state.get(SESSION_STATE_BLOB_CLIENT) # Get when needed for upload
    logger.info("Retrieved required Cosmos DB container clients.")


# --- Initialize Session State Variables ---
# Initialize only if they don't exist to preserve state across reruns
default_keys = [
    'form_default_title', 'form_default_instructions', 'form_default_num_people',
    'form_default_total_time', 'imported_image_url', 'original_source_type',
    'original_source_url', 'confirmed_ingredient_map', 'form_default_difficulty',
    'form_default_season', 'form_default_category' # Added category default key
]
default_values = ["", "", None, None, None, 'Manuale', None, {}, '', '', ''] # Added default for category
for key, default_value in zip(default_keys, default_values):
    if key not in st.session_state: st.session_state[key] = default_value
if 'manual_ingredients_df' not in st.session_state:
    st.session_state['manual_ingredients_df'] = pd.DataFrame([], columns=["Quantity", "Unit", "Ingredient Name", "Notes"])


# --- Pre-populate form if data was imported ---
# Check if there's data waiting from the import page
imported_data = st.session_state.get('imported_recipe_data', None)

if imported_data:
    st.success("Recipe data imported! Please review, structure ingredients if needed, and save.")
    logger.info("Pre-populating form state with imported data.")

    # Store defaults in session state for the current render cycle
    st.session_state['form_default_title'] = imported_data.get('title', '')
    st.session_state['form_default_instructions'] = imported_data.get('instructions_text', '')
    st.session_state['imported_image_url'] = imported_data.get('image_url')
    st.session_state['original_source_type'] = imported_data.get('source_type', 'Imported')
    st.session_state['original_source_url'] = imported_data.get('source_url')
    st.session_state['form_default_num_people'] = parse_servings(imported_data.get('yields'))
    try:
        total_time_raw = imported_data.get('total_time')
        st.session_state['form_default_total_time'] = int(total_time_raw) if total_time_raw is not None else None
    except (ValueError, TypeError):
         st.session_state['form_default_total_time'] = None
         logger.warning(f"Could not convert imported total_time '{total_time_raw}' to integer.")
    # Pre-populate category (assuming 'category' key exists in imported_data)
    st.session_state['form_default_category'] = imported_data.get('category', '') # Use empty string if not found
    logger.info(f"Imported category: '{st.session_state['form_default_category']}'")


    # --- Use the PARSED ingredients ---
    parsed_ingredients_list = imported_data.get('parsed_ingredients', [])
    initial_ingredients_df_data = [] # Reset list for building DataFrame data

    if parsed_ingredients_list:
        logger.info(f"Pre-populating ingredients editor with {len(parsed_ingredients_list)} parsed items.")
        # Convert the list of dicts directly to the format needed for the DataFrame
        for parsed_item in parsed_ingredients_list:
            initial_ingredients_df_data.append({
                "Quantity": parsed_item.get("quantity"), # Use parsed quantity
                "Unit": parsed_item.get("unit", ""),      # Use parsed unit or empty string
                "Ingredient Name": parsed_item.get("name", parsed_item.get("original","")), # Use parsed name or fallback
                "Notes": parsed_item.get("notes", "")     # Use parsed notes
            })
    else:
         # Fallback: Try parsing the raw text again if parsed_ingredients is missing/empty
         ingredients_text = imported_data.get('ingredients_text', '')
         if ingredients_text:
             logger.warning("Parsed ingredients list missing in imported data, attempting to parse raw text again.")
             for line in ingredients_text.strip().split('\n'):
                 if line.strip():
                     parsed = parse_ingredient_string(line.strip()) # Call parser here as fallback
                     initial_ingredients_df_data.append({
                         "Quantity": parsed.get("quantity"),
                         "Unit": parsed.get("unit", ""),
                         "Ingredient Name": parsed.get("name", line.strip()),
                         "Notes": parsed.get("notes", "(Imported - verify Qty/Unit)")
                     })
             logger.info(f"Fallback parsing created {len(initial_ingredients_df_data)} ingredient lines.")
         else:
             logger.warning("No parsed ingredients or raw ingredients text found in imported data.")

    # Set the initial state for the data editor
    st.session_state['manual_ingredients_df'] = pd.DataFrame(initial_ingredients_df_data)

    # --- IMPORTANT: Clear the temporary import data key ---
    # Do this AFTER processing it for the current run
    st.session_state['imported_recipe_data'] = None
    logger.info("Cleared imported_recipe_data from session state.")

    # NO RERUN HERE - Let the script continue to render the form with defaults

# --- Retrieve default values from session state for rendering ---
# These values persist across reruns unless cleared on save/failure
current_default_title = st.session_state.get('form_default_title', "")
current_default_instructions = st.session_state.get('form_default_instructions', "")
current_imported_image_url = st.session_state.get('imported_image_url')
current_default_num_people = st.session_state.get('form_default_num_people')
current_default_total_time = st.session_state.get('form_default_total_time')
current_default_difficulty = st.session_state.get('form_default_difficulty', '')
current_default_season = st.session_state.get('form_default_season', '')
current_default_category = st.session_state.get('form_default_category', '') # Get default category


# --- Display Imported Image (if available) ---
if current_imported_image_url:
    st.subheader("Imported Image Preview")
    st.image(current_imported_image_url, caption="Image from imported URL/Source", use_container_width=True)
    st.markdown("---")

# --- Recipe Input Form ---
# The form widgets will now use the 'current_default_...' variables set above
with st.form("recipe_form", clear_on_submit=True):
    st.subheader("Recipe Details")

    # Use current_default_... variables directly as values
    recipe_title = st.text_input("Recipe Title*", value=current_default_title, placeholder="E.g., Pasta al Pesto Genovese", key="recipe_title_input")
    recipe_instructions = st.text_area("Instructions*", value=current_default_instructions, height=300, placeholder="Describe the preparation steps...", key="recipe_instructions_input")

    # --- Other Fields ---
    col1, col2, col3 = st.columns(3)
    with col1:
        num_people = st.number_input("Servings (People)", min_value=1, step=1, value=current_default_num_people, key="num_people")
    with col2:
        difficulty_options = ["", "Easy", "Medium", "Hard", "Expert"]
        # Find index for default value if needed, otherwise default to 0 ("")
        difficulty_index = difficulty_options.index(current_default_difficulty) if current_default_difficulty in difficulty_options else 0
        difficulty = st.selectbox("Difficulty", options=difficulty_options, index=difficulty_index, key="difficulty")
    with col3:
        season_options = ["", "Any", "Spring", "Summer", "Autumn", "Winter"]
        season_index = season_options.index(current_default_season) if current_default_season in season_options else 0
        season = st.selectbox("Best Season", options=season_options, index=season_index, key="season")

    # Single Time Input
    total_time = st.number_input("Total Time (prep + cook, minutes)", min_value=0, step=5, value=current_default_total_time, key="total_time")

    # --- Category Input ---
    # Changed from selectbox to text_input, uses default value
    category = st.text_input("Category", value=current_default_category, placeholder="e.g., Primo, Main Course, Dessert", key="category_input")
    # --- END Category Input ---

    st.divider()

    st.subheader("Ingredients")
    st.markdown("Enter/Verify each ingredient below. Quantity and Name are required.")

    edited_ingredients_df = st.data_editor(
        st.session_state['manual_ingredients_df'], # Populated by import logic if applicable
        num_rows="dynamic", key="ingredients_editor",
        column_config={
            "Quantity": st.column_config.NumberColumn("Qty*", required=True),
            "Unit": st.column_config.TextColumn("Unit"), # Optional
            "Ingredient Name": st.column_config.TextColumn("Ingredient*", required=True),
            "Notes": st.column_config.TextColumn("Notes")
        }, use_container_width=True
    )
    # Don't update session state here, wait for submit button

    st.caption("* Quantity and Ingredient Name are required.")
    st.divider()
    submitted = st.form_submit_button("💾 Save Recipe")

# --- Form Submission Logic ---
if submitted:
    # Update session state with the final edited ingredients from the editor
    st.session_state['manual_ingredients_df'] = edited_ingredients_df
    st.markdown("--- Processing Submission ---")

    # 1. Retrieve data
    title = recipe_title
    instructions = recipe_instructions
    ingredients_data = edited_ingredients_df.copy() # Use the final edited data
    num_people_val = int(num_people) if num_people is not None else None
    difficulty_val = difficulty if difficulty else None
    season_val = season if season else None
    category_val = category.strip() if category else None # Get value from text_input
    total_time_val = int(total_time) if total_time is not None else None
    final_image_url = st.session_state.get('imported_image_url') # Get potentially imported URL
    # TODO: Add logic for handling NEW photo_upload widget value

    # 2. Validation
    validation_ok = True
    error_messages = []
    if not title: error_messages.append("Recipe Title is required.")
    if not instructions: error_messages.append("Recipe Instructions are required.")
    # Validate ingredients DataFrame
    ingredients_data.dropna(subset=['Ingredient Name'], inplace=True) # Drop rows if name is missing first
    if ingredients_data.empty:
         error_messages.append("Please add at least one valid ingredient row (with a name).")
    else:
        if ingredients_data["Quantity"].isnull().any(): error_messages.append("Quantity is required for all ingredients.")
        # Unit is optional

    if error_messages:
        validation_ok = False
        for msg in error_messages: st.error(msg)
        # --- Store current form values in session state if validation fails ---
        st.session_state['form_default_title'] = title
        st.session_state['form_default_instructions'] = instructions
        st.session_state['form_default_num_people'] = num_people # Store raw value from widget
        st.session_state['form_default_total_time'] = total_time # Store raw value from widget
        st.session_state['form_default_difficulty'] = difficulty # Store raw value from widget
        st.session_state['form_default_season'] = season # Store raw value from widget
        st.session_state['form_default_category'] = category # Store category too
        # manual_ingredients_df is already updated

    if validation_ok:
        st.success("Input validation passed. Processing ingredients...")
        logger.info(f"Form submitted for recipe: {title}")

        # 3. Process Ingredients (Logic remains the same)
        try:
            ingredient_items_list: List[IngredientItem] = []
            processed_ingredient_ids = {}
            all_ingredients_processed_successfully = True
            with st.spinner("Processing ingredients..."):
                # --- START: Ingredient Processing Logic ---
                for index, row in ingredients_data.iterrows():
                    # ... (Same logic as before: sanitize, check exact, check similar(TODO), upsert master, create item) ...
                    name = row['Ingredient Name']; qty = row['Quantity']; unit = row['Unit']; notes = row['Notes']
                    if not name or pd.isna(name) or not qty or pd.isna(qty): continue
                    name_lower = name.strip().lower(); confirmed_ingredient_id = None
                    if name_lower in processed_ingredient_ids: confirmed_ingredient_id = processed_ingredient_ids[name_lower]
                    else:
                        ingredient_id_candidate = sanitize_for_id(name)
                        existing_entity = get_ingredient_entity(ingredients_container, ingredient_id_candidate)
                        if existing_entity: confirmed_ingredient_id = existing_entity.id
                        else:
                            # TODO: Implement similarity check + HITL prompt
                            logger.warning(f"No exact match for '{name}'. Creating new entry.")
                            new_entity_data = IngredientEntity(id=ingredient_id_candidate, displayName=name.strip())
                            saved_entity = upsert_ingredient_entity(ingredients_container, new_entity_data)
                            if saved_entity: confirmed_ingredient_id = saved_entity.id
                            else: st.error(f"Failed to create master entry for '{name}'."); all_ingredients_processed_successfully = False; break
                        if confirmed_ingredient_id: processed_ingredient_ids[name_lower] = confirmed_ingredient_id
                        else: st.error(f"Failed to determine ID for '{name}'."); all_ingredients_processed_successfully = False; break
                    if confirmed_ingredient_id:
                        ingredient_item = IngredientItem(ingredient_id=confirmed_ingredient_id, quantity=float(qty), unit=str(unit).strip() if pd.notna(unit) else None, notes=str(notes).strip() if pd.notna(notes) else None)
                        ingredient_items_list.append(ingredient_item)
                # --- END: Ingredient Processing Logic ---

            if not all_ingredients_processed_successfully:
                 st.error("Recipe saving aborted due to ingredient processing errors.")
            else:
                # 4. Get Category (Now from text input)
                confirmed_category = category_val
                logger.info(f"Using category: {confirmed_category}")

                # 5. Create Recipe Pydantic Object
                logger.info("Creating final Recipe object...")
                try:
                    current_time_utc = datetime.now(timezone.utc)
                    source_type_final = st.session_state.get('original_source_type', 'Manuale')
                    source_url_final = st.session_state.get('original_source_url')

                    new_recipe = Recipe(
                        title=title.strip(),
                        instructions=instructions.strip(),
                        ingredients=ingredient_items_list,
                        category=confirmed_category, # Use the renamed field
                        num_people=num_people_val,
                        difficulty=difficulty_val,
                        season=season_val,
                        total_time_minutes=total_time_val,
                        source_type=source_type_final,
                        source_url=source_url_final,
                        image_url=final_image_url,
                        created_at=current_time_utc,
                        updated_at=current_time_utc
                    )

                    # 6. Save Recipe
                    logger.info("Attempting to save recipe...")
                    with st.spinner("Saving recipe..."):
                        if not recipe_container: raise ValueError("Client missing.")
                        saved_recipe = save_recipe(recipe_container, new_recipe)

                    if saved_recipe:
                        st.success(f"Recipe '{saved_recipe.title}' saved successfully!")
                        # Clear state used for this form run
                        st.session_state['manual_ingredients_df'] = pd.DataFrame([], columns=["Quantity", "Unit", "Ingredient Name", "Notes"])
                        st.session_state['confirmed_ingredient_map'] = {}
                        st.session_state['imported_image_url'] = None
                        st.session_state['form_default_title'] = ""
                        st.session_state['form_default_instructions'] = ""
                        st.session_state['original_source_type'] = 'Manuale'
                        st.session_state['original_source_url'] = None
                        st.session_state['form_default_num_people'] = None
                        st.session_state['form_default_total_time'] = None
                        st.session_state['form_default_difficulty'] = ''
                        st.session_state['form_default_season'] = ''
                        st.session_state['form_default_category'] = '' # Clear category default

                        st.rerun() # Reset form and show success
                    else:
                        st.error("Failed to save recipe. Check logs.")
                        # Store current form values in session state if save fails
                        st.session_state['form_default_title'] = title
                        st.session_state['form_default_instructions'] = instructions
                        st.session_state['form_default_num_people'] = num_people
                        st.session_state['form_default_total_time'] = total_time
                        st.session_state['form_default_difficulty'] = difficulty
                        st.session_state['form_default_season'] = season
                        st.session_state['form_default_category'] = category # Store category

                except Exception as model_error:
                     st.error(f"Error creating recipe data: {model_error}")
                     logger.error(f"Pydantic/object creation error: {model_error}", exc_info=True)
        except Exception as e:
            st.error(f"An unexpected error occurred: {e}")
            logger.error(f"Error during recipe processing/saving: {e}", exc_info=True)

# --- Clean up temporary form defaults after rendering ---
# Removed the cleanup block as state is managed on success/failure now

