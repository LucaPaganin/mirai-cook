# -*- coding: utf-8 -*-
"""
Streamlit page for manually adding or editing recipes in Mirai Cook.
Handles pre-population of form fields if data is imported from page 3.
Integrates Levenshtein check for similar ingredients during saving.
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
       find_similar_ingredient_display_names, # Import the similarity function
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
    'form_default_season', 'form_default_category', 'form_default_drink',
    'pending_similarity_check' # NEW state for HITL
]
default_values = ["", "", None, None, None, 'Manuale', None, {}, '', '', '', '', None] # Added default for pending check
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
    st.session_state['form_default_category'] = imported_data.get('category', '')
    st.session_state['form_default_drink'] = imported_data.get('drink', '')


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
current_default_category = st.session_state.get('form_default_category', '')
current_default_drink = st.session_state.get('form_default_drink', '') # Get default drink


# --- Display Imported Image (if available) ---
if current_imported_image_url:
    st.subheader("Imported Image Preview")
    st.image(current_imported_image_url, caption="Image from imported URL/Source", use_container_width=True)
    st.markdown("---")

# --- Handle Pending Similarity Check (HITL Prompt) ---
# This section appears *outside* the form if a check is pending
pending_check = st.session_state.get('pending_similarity_check')
if pending_check:
    st.warning(f"Potential duplicate found for: **{pending_check['new_name']}**")
    st.write("This ingredient is very similar to the following existing ingredient(s):")

    options = {} # Map display option to ingredient ID
    for entity in pending_check['similar_entities']:
        option_text = f"Use existing: '{entity.displayName}' (ID: {entity.id})"
        options[option_text] = entity.id

    create_new_option = f"Create new entry for: '{pending_check['new_name']}' (ID: {pending_check['candidate_id']})"
    options[create_new_option] = pending_check['candidate_id'] # Use the candidate ID if creating new

    # Use columns for better layout
    col_prompt, col_confirm = st.columns([3,1])
    with col_prompt:
        user_choice_display = st.radio(
            "Select an action:",
            options=list(options.keys()),
            key=f"similarity_choice_{pending_check['candidate_id']}",
            index=0 # Default to first similar option
        )
    with col_confirm:
        st.write("") # Spacer
        st.write("") # Spacer
        if st.button("Confirm Ingredient Choice", key=f"confirm_similarity_{pending_check['candidate_id']}"):
            chosen_id = options[user_choice_display]
            # Store the confirmed mapping in session state
            st.session_state['confirmed_ingredient_map'][pending_check['new_name'].strip().lower()] = chosen_id
            # If the choice was to create new, we still need to ensure the entity exists
            if chosen_id == pending_check['candidate_id']:
                 # Double check if it somehow got created between check and confirm
                 existing = get_ingredient_entity(ingredients_container, chosen_id)
                 if not existing:
                     logger.info(f"User chose to create new. Creating IngredientEntity for '{pending_check['new_name']}' with ID '{chosen_id}'")
                     new_entity_data = IngredientEntity(id=chosen_id, displayName=pending_check['new_name'].strip())
                     saved = upsert_ingredient_entity(ingredients_container, new_entity_data)
                     if not saved:
                         st.error(f"Failed to create master entry for new ingredient: '{pending_check['new_name']}'.")
                         # How to handle this error? Maybe clear the pending check and force user to re-submit form?
                     else:
                         logger.info(f"Created new IngredientEntity: {chosen_id}")
                 else:
                      logger.info(f"User chose to create new, but ID '{chosen_id}' already exists now. Using existing.")

            # Clear the pending check state and rerun to proceed with saving
            st.session_state['pending_similarity_check'] = None
            st.success(f"Choice confirmed for '{pending_check['new_name']}'. Please click 'Save Recipe' again to complete the process.")
            # We need to rerun to remove the prompt and re-enable the form
            st.rerun()

# --- Recipe Input Form ---
# Disable form submission if a similarity check is pending
form_disabled = st.session_state.get('pending_similarity_check') is not None
with st.form("recipe_form", clear_on_submit=True):
    st.subheader("Recipe Details")
    # Input widgets for title, instructions, etc.
    recipe_title = st.text_input("Recipe Title*", value=current_default_title, key="recipe_title_input", disabled=form_disabled)
    recipe_instructions = st.text_area("Instructions*", value=current_default_instructions, height=300, key="recipe_instructions_input", disabled=form_disabled)
    col1, col2, col3 = st.columns(3);
    with col1: num_people = st.number_input("Servings (People)", min_value=1, step=1, value=current_default_num_people, key="num_people", disabled=form_disabled)
    with col2: difficulty_options = ["", "Easy", "Medium", "Hard", "Expert"]; difficulty_index = difficulty_options.index(current_default_difficulty) if current_default_difficulty in difficulty_options else 0; difficulty = st.selectbox("Difficulty", options=difficulty_options, index=difficulty_index, key="difficulty", disabled=form_disabled)
    with col3: season_options = ["", "Any", "Spring", "Summer", "Autumn", "Winter"]; season_index = season_options.index(current_default_season) if current_default_season in season_options else 0; season = st.selectbox("Best Season", options=season_options, index=season_index, key="season", disabled=form_disabled)
    total_time = st.number_input("Total Time (prep + cook, minutes)", min_value=0, step=5, value=current_default_total_time, key="total_time", disabled=form_disabled)
    category = st.text_input("Category", value=current_default_category, placeholder="e.g., Primo, Main Course, Dessert", key="category_input", disabled=form_disabled)
    drink_pairing = st.text_input("Suggested Drink Pairing (Optional)", value=current_default_drink, placeholder="e.g., Chianti Classico", key="drink_input", disabled=form_disabled)

    st.divider()
    st.subheader("Ingredients")
    st.markdown("Enter/Verify each ingredient below. Quantity and Name are required.")
    edited_ingredients_df = st.data_editor(st.session_state['manual_ingredients_df'], num_rows="dynamic", key="ingredients_editor", column_config={"Quantity": st.column_config.NumberColumn("Qty*", required=True), "Unit": st.column_config.TextColumn("Unit"), "Ingredient Name": st.column_config.TextColumn("Ingredient*", required=True), "Notes": st.column_config.TextColumn("Notes")}, use_container_width=True, disabled=form_disabled)
    st.caption("* Quantity and Ingredient Name are required.")
    st.divider()
    recipe_course_manual = st.selectbox("Recipe Course (Manual)", ["", "Antipasto", "Primo", "Secondo", "Contorno", "Dolce", "Piatto Unico", "Altro"], index=0, placeholder="Select category...", key="porta_cat", disabled=form_disabled) # Consider removing if category text input is primary
    st.divider()
    submitted = st.form_submit_button("💾 Save Recipe", disabled=form_disabled) # Disable button if check pending

# --- Form Submission Logic ---
if submitted and not form_disabled: # Process only if submitted and not disabled
    # Update session state with the final edited ingredients from the editor
    st.session_state['manual_ingredients_df'] = edited_ingredients_df
    st.markdown("--- Processing Submission ---")

    # 1. Retrieve data
    title = recipe_title; instructions = recipe_instructions; ingredients_data = edited_ingredients_df.copy()
    num_people_val = int(num_people) if num_people is not None else None; difficulty_val = difficulty if difficulty else None; season_val = season if season else None
    category_val = category.strip() if category else None; total_time_val = int(total_time) if total_time is not None else None; drink_val = drink_pairing.strip() if drink_pairing else None
    final_image_url = st.session_state.get('imported_image_url')
    # TODO: Add logic for handling NEW photo_upload widget value

    # 2. Validation
    validation_ok = True; error_messages = []
    if not title: error_messages.append("Recipe Title is required.")
    if not instructions: error_messages.append("Recipe Instructions are required.")
    ingredients_data.dropna(subset=['Ingredient Name'], inplace=True)
    if ingredients_data.empty: error_messages.append("Please add at least one valid ingredient row (with a name).")
    else:
        if ingredients_data["Quantity"].isnull().any(): error_messages.append("Quantity is required for all ingredients.")
    if error_messages:
        validation_ok = False;
        for msg in error_messages: st.error(msg)
        # Store current form values if validation fails
        st.session_state['form_default_title'] = title; st.session_state['form_default_instructions'] = instructions; st.session_state['form_default_num_people'] = num_people
        st.session_state['form_default_total_time'] = total_time; st.session_state['form_default_difficulty'] = difficulty; st.session_state['form_default_season'] = season
        st.session_state['form_default_category'] = category; st.session_state['form_default_drink'] = drink_pairing

    if validation_ok:
        st.success("Input validation passed. Processing ingredients...")
        logger.info(f"Form submitted for recipe: {title}")

        # 3. Process Ingredients (Integrate Similarity Check)
        try:
            ingredient_items_list: List[IngredientItem] = []
            # Use confirmed map from previous HITL steps in this session
            processed_ingredient_ids = st.session_state.get('confirmed_ingredient_map', {})
            all_ingredients_processed_successfully = True
            needs_similarity_check = None # Store info if HITL needed

            with st.spinner("Processing ingredients..."):
                # --- START: Ingredient Processing Logic with Similarity ---
                for index, row in ingredients_data.iterrows():
                    name = row['Ingredient Name']; qty = row['Quantity']; unit = row['Unit']; notes = row['Notes']
                    if not name or pd.isna(name) or not qty or pd.isna(qty): continue
                    name_lower = name.strip().lower(); confirmed_ingredient_id = None

                    # Check if already confirmed via HITL in this session
                    if name_lower in processed_ingredient_ids:
                        confirmed_ingredient_id = processed_ingredient_ids[name_lower]
                        logger.info(f"Using confirmed/cached ID '{confirmed_ingredient_id}' for ingredient '{name}'")
                    else:
                        # a. Sanitize name
                        ingredient_id_candidate = sanitize_for_id(name)
                        # b. Check exact match
                        existing_entity = get_ingredient_entity(ingredients_container, ingredient_id_candidate)
                        if existing_entity:
                            confirmed_ingredient_id = existing_entity.id
                            logger.info(f"Exact match found for '{name}'. Using ID: {confirmed_ingredient_id}")
                            processed_ingredient_ids[name_lower] = confirmed_ingredient_id # Add to cache for this run
                        else:
                            # c. Check similarity
                            logger.info(f"No exact match for ID '{ingredient_id_candidate}'. Checking similar names for '{name}'...")
                            similar_entities = find_similar_ingredient_display_names(ingredients_container, name.strip())
                            if similar_entities:
                                logger.warning(f"Found similar ingredients for '{name}': {[e.displayName for e in similar_entities]}")
                                # --- PAUSE & REQUEST USER INPUT (HITL) ---
                                needs_similarity_check = {
                                    "new_name": name.strip(),
                                    "candidate_id": ingredient_id_candidate,
                                    "similar_entities": similar_entities
                                }
                                st.session_state['pending_similarity_check'] = needs_similarity_check
                                all_ingredients_processed_successfully = False # Stop processing further ingredients for now
                                logger.info("Paused ingredient processing, pending user similarity confirmation.")
                                break # Exit the ingredient processing loop to show the prompt
                            else:
                                # d. No similar found, create new
                                logger.info(f"No similar ingredients found. Creating new entry for '{name}' with ID '{ingredient_id_candidate}'.")
                                new_entity_data = IngredientEntity(id=ingredient_id_candidate, displayName=name.strip())
                                saved_entity = upsert_ingredient_entity(ingredients_container, new_entity_data)
                                if saved_entity:
                                    confirmed_ingredient_id = saved_entity.id
                                    processed_ingredient_ids[name_lower] = confirmed_ingredient_id # Add to cache
                                    logger.info(f"Created new IngredientEntity: {confirmed_ingredient_id}")
                                else:
                                    st.error(f"Failed to create master entry for '{name}'."); all_ingredients_processed_successfully = False; break

                    # e. Create IngredientItem if ID confirmed for this iteration
                    if confirmed_ingredient_id:
                        ingredient_item = IngredientItem(ingredient_id=confirmed_ingredient_id, quantity=float(qty), unit=str(unit).strip() if pd.notna(unit) else None, notes=str(notes).strip() if pd.notna(notes) else None)
                        ingredient_items_list.append(ingredient_item)
                    elif not needs_similarity_check: # If loop finished without needing check but ID is missing (shouldn't happen)
                         st.error(f"Failed to determine ID for ingredient: '{name}'.")
                         all_ingredients_processed_successfully = False; break
                # --- END: Ingredient Processing Logic ---

            # Check if we were interrupted by a similarity check
            if st.session_state.get('pending_similarity_check'):
                 st.warning("Please resolve the ingredient similarity check above before saving.")
                 # Store current form values so they are not lost on rerun
                 st.session_state['form_default_title'] = title; st.session_state['form_default_instructions'] = instructions; st.session_state['form_default_num_people'] = num_people
                 st.session_state['form_default_total_time'] = total_time; st.session_state['form_default_difficulty'] = difficulty; st.session_state['form_default_season'] = season
                 st.session_state['form_default_category'] = category; st.session_state['form_default_drink'] = drink_pairing
                 st.rerun() # Rerun to display the prompt outside the form

            elif not all_ingredients_processed_successfully:
                 st.error("Recipe saving aborted due to ingredient processing errors.")
            else:
                # --- Proceed to Save Recipe (Only if no pending check and all ingredients processed) ---
                st.success("All ingredients processed successfully.")
                logger.info("Ingredient processing complete.")

                # 4. Get Category
                confirmed_category = category_val
                logger.info(f"Using category: {confirmed_category}")

                # 5. Create Recipe Pydantic Object
                logger.info("Creating final Recipe object...")
                try:
                    current_time_utc = datetime.now(timezone.utc)
                    source_type_final = st.session_state.get('original_source_type', 'Manuale')
                    source_url_final = st.session_state.get('original_source_url')

                    new_recipe = Recipe(
                        title=title.strip(), instructions=instructions.strip(), ingredients=ingredient_items_list,
                        category=confirmed_category, num_people=num_people_val, difficulty=difficulty_val,
                        season=season_val, total_time_minutes=total_time_val, drink=drink_val,
                        source_type=source_type_final, source_url=source_url_final, image_url=final_image_url,
                        created_at=current_time_utc, updated_at=current_time_utc
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
                        st.session_state['form_default_category'] = ''
                        st.session_state['form_default_drink'] = ''

                        st.rerun() # Reset form and show success
                    else:
                        st.error("Failed to save recipe. Check logs.")
                        # Store current form values in session state if save fails
                        st.session_state['form_default_title'] = title; st.session_state['form_default_instructions'] = instructions; st.session_state['form_default_num_people'] = num_people
                        st.session_state['form_default_total_time'] = total_time; st.session_state['form_default_difficulty'] = difficulty; st.session_state['form_default_season'] = season
                        st.session_state['form_default_category'] = category; st.session_state['form_default_drink'] = drink_pairing

                except Exception as model_error:
                     st.error(f"Error creating recipe data: {model_error}")
                     logger.error(f"Pydantic/object creation error: {model_error}", exc_info=True)
        except Exception as e:
            st.error(f"An unexpected error occurred: {e}")
            logger.error(f"Error during recipe processing/saving: {e}", exc_info=True)

# --- No Cleanup block needed at the end ---

