# -*- coding: utf-8 -*-
"""
Streamlit page for manually adding or editing recipes in Mirai Cook.
Handles pre-population of form fields if data is imported from page 3,
including displaying an imported image URL and pre-filling title/instructions.
"""

import streamlit as st
import pandas as pd
from datetime import datetime, timezone
import logging
import sys
import os
from typing import List, Optional

# --- Setup Project Root Path ---
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# --- Import Application Modules ---
try:
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
# Use specific keys for pre-population values to avoid conflicts
if 'form_default_title' not in st.session_state:
    st.session_state['form_default_title'] = ""
if 'form_default_instructions' not in st.session_state:
    st.session_state['form_default_instructions'] = ""
if 'manual_ingredients_df' not in st.session_state:
    st.session_state['manual_ingredients_df'] = pd.DataFrame([], columns=["Quantity", "Unit", "Ingredient Name", "Notes"])
if 'confirmed_ingredient_map' not in st.session_state:
   st.session_state['confirmed_ingredient_map'] = {}
if 'imported_image_url' not in st.session_state:
    st.session_state['imported_image_url'] = None
# Add state for source info if needed
if 'original_source_type' not in st.session_state:
    st.session_state['original_source_type'] = 'Manuale'
if 'original_source_url' not in st.session_state:
    st.session_state['original_source_url'] = None


# --- Pre-populate form if data was imported ---
# Check if there's data waiting from the import page
imported_data = st.session_state.get('imported_recipe_data', None)

if imported_data:
    st.success("Recipe data imported! Please review, structure ingredients, and save.")
    logger.info("Pre-populating form state with imported data.")

    # Store defaults in session state BEFORE clearing and rerunning
    st.session_state['form_default_title'] = imported_data.get('title', '')
    st.session_state['form_default_instructions'] = imported_data.get('instructions_text', '')
    st.session_state['imported_image_url'] = imported_data.get('image_url')
    st.session_state['original_source_type'] = imported_data.get('source_type', 'Imported')
    st.session_state['original_source_url'] = imported_data.get('source_url')

    # Attempt to pre-populate ingredients editor from the raw text
    ingredients_text = imported_data.get('ingredients_text', '')
    initial_ingredients_df_data = []
    if ingredients_text:
        for line in ingredients_text.strip().split('\n'):
            if line.strip():
                initial_ingredients_df_data.append({
                    "Quantity": None, "Unit": "", "Ingredient Name": line.strip(),
                    "Notes": "(Imported - verify Qty/Unit)"
                })
        logger.info(f"Prepared {len(initial_ingredients_df_data)} ingredient lines for editor.")
    else:
         logger.info("No ingredients text found in imported data.")
    st.session_state['manual_ingredients_df'] = pd.DataFrame(initial_ingredients_df_data)

    # Clear the temporary import data key now that we've processed it
    st.session_state['imported_recipe_data'] = None
    logger.info("Cleared imported_recipe_data from session state.")

    # Force a rerun to render the page with the pre-filled state
    st.rerun()

# --- Retrieve default values from session state for this render ---
# These values were set in the 'if imported_data:' block before the rerun
current_default_title = st.session_state.get('form_default_title', "")
current_default_instructions = st.session_state.get('form_default_instructions', "")
current_imported_image_url = st.session_state.get('imported_image_url')

# --- Display Imported Image (if available) ---
if current_imported_image_url:
    st.subheader("Imported Image Preview")
    st.image(current_imported_image_url, caption="Image from imported URL/Source", use_container_width=True)
    st.markdown("---") # Separator

# --- Recipe Input Form ---
# The form widgets will now use the default values retrieved from session state
with st.form("recipe_form", clear_on_submit=True):
    st.subheader("Recipe Details")

    # Use current_default_title and current_default_instructions
    recipe_title = st.text_input("Recipe Title*", value=current_default_title, placeholder="E.g., Pasta al Pesto Genovese", key="recipe_title_input")
    recipe_instructions = st.text_area("Instructions*", value=current_default_instructions, height=300, placeholder="Describe the preparation steps...", key="recipe_instructions_input")

    # --- Other Fields ---
    col1, col2, col3 = st.columns(3)
    with col1:
        # TODO: Pre-populate num_people if available
        num_people = st.number_input("Servings (People)", min_value=1, step=1, value=None, key="num_people")
    with col2:
        difficulty_options = ["", "Easy", "Medium", "Hard", "Expert"]
        # TODO: Pre-populate difficulty if available
        difficulty = st.selectbox("Difficulty", options=difficulty_options, index=0, key="difficulty")
    with col3:
        season_options = ["", "Any", "Spring", "Summer", "Autumn", "Winter"]
        # TODO: Pre-populate season if available
        season = st.selectbox("Best Season", options=season_options, index=0, key="season")

    col_prep, col_cook = st.columns(2)
    with col_prep:
        # TODO: Pre-populate prep_time if available
        prep_time = st.number_input("Prep Time (minutes)", min_value=0, step=5, value=None, key="prep_time")
    with col_cook:
        # TODO: Pre-populate cook_time if available
        cook_time = st.number_input("Cook Time (minutes)", min_value=0, step=5, value=None, key="cook_time")

    st.divider()

    st.subheader("Ingredients")
    st.markdown("Enter/Verify each ingredient below. **Please structure Quantity and Unit.**")

    edited_ingredients_df = st.data_editor(
        st.session_state['manual_ingredients_df'], # Populated by import logic if applicable
        num_rows="dynamic", key="ingredients_editor",
        column_config={
            "Quantity": st.column_config.NumberColumn("Qty*", required=True),
            "Unit": st.column_config.TextColumn("Unit*", required=True),
            "Ingredient Name": st.column_config.TextColumn("Ingredient*", required=True),
            "Notes": st.column_config.TextColumn("Notes")
        }, use_container_width=True
    )
    st.session_state['manual_ingredients_df'] = edited_ingredients_df # Keep state updated
    st.caption("* Quantity, Unit, and Ingredient Name are required.")

    st.divider()

    st.markdown("**Category:** (Automatic suggestion and selection to be added)")
    portata_category_manual = st.selectbox("Recipe Category (Manual)", ["", "Antipasto", "Primo", "Secondo", "Contorno", "Dolce", "Piatto Unico", "Altro"], index=0, placeholder="Select category...", key="porta_cat")

    st.divider()
    submitted = st.form_submit_button("💾 Save Recipe")

# --- Form Submission Logic ---
if submitted:
    st.session_state['manual_ingredients_df'] = edited_ingredients_df # Persist latest edits
    st.markdown("--- Processing Submission ---")

    # 1. Retrieve data
    title = recipe_title
    instructions = recipe_instructions
    ingredients_data = edited_ingredients_df.copy()
    num_people_val = int(num_people) if num_people is not None else None
    difficulty_val = difficulty if difficulty else None
    season_val = season if season else None
    portata_category_val = porta_category_manual if porta_category_manual else None
    prep_time_val = int(prep_time) if prep_time is not None else None
    cook_time_val = int(cook_time) if cook_time is not None else None
    # Determine final image URL (use imported if no new upload logic added yet)
    final_image_url = st.session_state.get('imported_image_url')
    # --- TODO: Add logic for handling NEW photo_upload widget value ---

    # 2. Validation
    validation_ok = True
    error_messages = []
    if not title: error_messages.append("Recipe Title is required.")
    if not instructions: error_messages.append("Recipe Instructions are required.")
    ingredients_data.dropna(subset=['Ingredient Name'], inplace=True)
    if ingredients_data.empty:
         error_messages.append("Please add at least one valid ingredient row (with a name).")
    else:
        if ingredients_data["Quantity"].isnull().any(): error_messages.append("Quantity is required for all ingredients.")
        if ingredients_data["Unit"].isnull().any() or (ingredients_data["Unit"] == '').any(): error_messages.append("Unit is required for all ingredients.")

    if error_messages:
        validation_ok = False
        for msg in error_messages: st.error(msg)

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
                    if not name or pd.isna(name) or not qty or pd.isna(qty) or not unit or pd.isna(unit): continue
                    name_lower = name.strip().lower(); confirmed_ingredient_id = None
                    if name_lower in processed_ingredient_ids: confirmed_ingredient_id = processed_ingredient_ids[name_lower]
                    else:
                        ingredient_id_candidate = sanitize_for_id(name)
                        existing_entity = get_ingredient_entity(ingredients_container, ingredient_id_candidate)
                        if existing_entity: confirmed_ingredient_id = existing_entity.id
                        else:
                            logger.warning(f"No exact match for '{name}'. Creating new entry.")
                            new_entity_data = IngredientEntity(id=ingredient_id_candidate, displayName=name.strip())
                            saved_entity = upsert_ingredient_entity(ingredients_container, new_entity_data)
                            if saved_entity: confirmed_ingredient_id = saved_entity.id
                            else: st.error(f"Failed to create master entry for '{name}'."); all_ingredients_processed_successfully = False; break
                        if confirmed_ingredient_id: processed_ingredient_ids[name_lower] = confirmed_ingredient_id
                        else: st.error(f"Failed to determine ID for '{name}'."); all_ingredients_processed_successfully = False; break
                    if confirmed_ingredient_id:
                        ingredient_item = IngredientItem(ingredient_id=confirmed_ingredient_id, quantity=float(qty), unit=str(unit).strip(), notes=str(notes).strip() if pd.notna(notes) else None)
                        ingredient_items_list.append(ingredient_item)
                # --- END: Ingredient Processing Logic ---

            if not all_ingredients_processed_successfully:
                 st.error("Recipe saving aborted due to ingredient processing errors.")
            else:
                # 4. Get Category (Manual for now)
                confirmed_category = portata_category_val
                logger.info(f"Using category: {confirmed_category}")

                # 5. Create Recipe Pydantic Object
                logger.info("Creating final Recipe object...")
                try:
                    current_time_utc = datetime.now(timezone.utc)
                    # Retrieve original source info from session state
                    source_type_final = st.session_state.get('original_source_type', 'Manuale')
                    source_url_final = st.session_state.get('original_source_url')

                    new_recipe = Recipe(
                        title=title.strip(),
                        instructions=instructions.strip(),
                        ingredients=ingredient_items_list,
                        portata_category=confirmed_category,
                        num_people=num_people_val,
                        difficulty=difficulty_val,
                        season=season_val,
                        prep_time_minutes=prep_time_val,
                        cook_time_minutes=cook_time_val,
                        source_type=source_type_final, # Use stored source type
                        source_url=source_url_final,   # Use stored source url
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
                        # Clear state used for pre-population and editing
                        st.session_state['manual_ingredients_df'] = pd.DataFrame([], columns=["Quantity", "Unit", "Ingredient Name", "Notes"])
                        st.session_state['confirmed_ingredient_map'] = {}
                        st.session_state['imported_image_url'] = None
                        st.session_state['form_default_title'] = "" # Clear defaults
                        st.session_state['form_default_instructions'] = ""
                        st.session_state['original_source_type'] = 'Manuale' # Reset source
                        st.session_state['original_source_url'] = None
                        st.rerun() # Reset form
                    else:
                        st.error("Failed to save recipe. Check logs.")
                except Exception as model_error:
                     st.error(f"Error creating recipe data: {model_error}")
                     logger.error(f"Pydantic/object creation error: {model_error}", exc_info=True)
        except Exception as e:
            st.error(f"An unexpected error occurred: {e}")
            logger.error(f"Error during recipe processing/saving: {e}", exc_info=True)

# --- Clean up temporary form defaults after rendering ---
# This ensures that if the user navigates away and back without importing again,
# the form starts empty.
if 'form_default_title' in st.session_state:
    del st.session_state['form_default_title']
if 'form_default_instructions' in st.session_state:
    del st.session_state['form_default_instructions']
# Keep 'imported_image_url' until explicitly replaced or cleared on save/new import
# Keep 'manual_ingredients_df' as it holds user edits within the form session

