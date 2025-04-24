# -*- coding: utf-8 -*-
"""
Streamlit page for manually adding or editing recipes in Mirai Cook.
Handles pre-population of form fields including calories.
Includes optional 'drink' pairing field and calorie input.
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
if project_root not in sys.path: sys.path.insert(0, project_root)

# --- Import Application Modules ---
try:
    # Recipe model now includes 'drink'
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
    )
    from src.utils import parse_ingredient_string, parse_servings
except ImportError as e:
    st.error(f"Error importing application modules: {e}. Check PYTHONPATH.")
    st.stop()

# --- Configure Logging ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Page Configuration ---
try: st.set_page_config(page_title="Add/Edit Recipe - Mirai Cook", page_icon="✍️")
except st.errors.StreamlitAPIException: pass

st.title("✍️ Add / Edit Recipe")

# --- Check if NECESSARY Azure Clients are Initialized ---
required_clients = [SESSION_STATE_RECIPE_CONTAINER, SESSION_STATE_INGREDIENT_CONTAINER]
clients_ready = True; missing_clients = []
for client_key in required_clients:
    if not st.session_state.get(client_key): clients_ready = False; missing_clients.append(client_key.replace("container", "Container Client"))
if not clients_ready:
    st.error(f"Error: Required Azure connections missing: {', '.join(missing_clients)}.")
    if not st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED): st.warning("Global Azure init reported issues.")
    st.stop()
else:
    recipe_container = st.session_state[SESSION_STATE_RECIPE_CONTAINER]
    ingredients_container = st.session_state[SESSION_STATE_INGREDIENT_CONTAINER]
    logger.info("Retrieved required Cosmos DB container clients.")


# --- Initialize Session State Variables ---
default_keys = [
    'form_default_title', 'form_default_instructions', 'form_default_num_people',
    'form_default_total_time', 'imported_image_url', 'original_source_type',
    'original_source_url', 'confirmed_ingredient_map', 'form_default_difficulty',
    'form_default_season', 'form_default_category', 'form_default_drink',
    'pending_similarity_check', 'form_default_calories' # Added calories default key
]
default_values = ["", "", None, None, None, 'Manuale', None, {}, '', '', '', '', None, None] # Added default for calories
for key, default_value in zip(default_keys, default_values):
    if key not in st.session_state: st.session_state[key] = default_value
if 'manual_ingredients_df' not in st.session_state:
    st.session_state['manual_ingredients_df'] = pd.DataFrame([], columns=["Quantity", "Unit", "Ingredient Name", "Notes"])


# --- Pre-populate form if data was imported ---
imported_data = st.session_state.get('imported_recipe_data', None)
if imported_data:
    st.success("Recipe data imported! Please review, structure ingredients if needed, and save.")
    logger.info("Pre-populating form state with imported data.")
    # Store defaults in session state
    st.session_state['form_default_title'] = imported_data.get('title', '')
    st.session_state['form_default_instructions'] = imported_data.get('instructions_text', '')
    st.session_state['imported_image_url'] = imported_data.get('image_url')
    st.session_state['original_source_type'] = imported_data.get('source_type', 'Imported')
    st.session_state['original_source_url'] = imported_data.get('source_url')
    st.session_state['form_default_num_people'] = parse_servings(imported_data.get('yields'))
    try: total_time_raw = imported_data.get('total_time'); st.session_state['form_default_total_time'] = int(total_time_raw) if total_time_raw is not None else None
    except (ValueError, TypeError): st.session_state['form_default_total_time'] = None
    st.session_state['form_default_category'] = imported_data.get('category', '')
    st.session_state['form_default_drink'] = imported_data.get('drink', '')
    # Pre-populate calories
    try: calories_raw = imported_data.get('calories'); st.session_state['form_default_calories'] = int(calories_raw) if calories_raw is not None else None
    except (ValueError, TypeError): st.session_state['form_default_calories'] = None; logger.warning(f"Could not convert imported calories '{calories_raw}' to integer.")
    logger.info(f"Imported calories: '{st.session_state['form_default_calories']}'")

    # Pre-populate ingredients editor
    parsed_ingredients_list = imported_data.get('parsed_ingredients', [])
    initial_ingredients_df_data = []
    if parsed_ingredients_list:
        for parsed_item in parsed_ingredients_list: initial_ingredients_df_data.append({"Quantity": parsed_item.get("quantity"), "Unit": parsed_item.get("unit", ""), "Ingredient Name": parsed_item.get("name", parsed_item.get("original","")), "Notes": parsed_item.get("notes", "")})
    st.session_state['manual_ingredients_df'] = pd.DataFrame(initial_ingredients_df_data)
    # Clear the temporary import data key
    st.session_state['imported_recipe_data'] = None
    logger.info("Cleared imported_recipe_data from session state.")
    # NO RERUN NEEDED

# --- Retrieve default values from session state for rendering ---
current_default_title = st.session_state.get('form_default_title', "")
current_default_instructions = st.session_state.get('form_default_instructions', "")
current_imported_image_url = st.session_state.get('imported_image_url')
current_default_num_people = st.session_state.get('form_default_num_people')
current_default_total_time = st.session_state.get('form_default_total_time')
current_default_difficulty = st.session_state.get('form_default_difficulty', '')
current_default_season = st.session_state.get('form_default_season', '')
current_default_category = st.session_state.get('form_default_category', '')
current_default_drink = st.session_state.get('form_default_drink', '')
current_default_calories = st.session_state.get('form_default_calories') # Get default calories

# --- Display Imported Image (if available) ---
if current_imported_image_url:
    st.subheader("Imported Image Preview")
    st.image(current_imported_image_url, caption="Image from imported URL/Source", use_container_width=True)
    st.markdown("---")

# --- Handle Pending Similarity Check (HITL Prompt) ---
pending_check = st.session_state.get('pending_similarity_check')
if pending_check:
    # ... (Similarity check UI logic remains the same) ...
    st.warning(f"Potential duplicate found for: **{pending_check['new_name']}**")
    st.write("This ingredient is very similar to the following existing ingredient(s):")
    options = {}
    for entity in pending_check['similar_entities']: option_text = f"Use existing: '{entity.displayName}' (ID: {entity.id})"; options[option_text] = entity.id
    create_new_option = f"Create new entry for: '{pending_check['new_name']}' (ID: {pending_check['candidate_id']})"; options[create_new_option] = pending_check['candidate_id']
    col_prompt, col_confirm = st.columns([3,1])
    with col_prompt: user_choice_display = st.radio("Select an action:", options=list(options.keys()), key=f"similarity_choice_{pending_check['candidate_id']}", index=0)
    with col_confirm:
        st.write("") ; st.write("")
        if st.button("Confirm Ingredient Choice", key=f"confirm_similarity_{pending_check['candidate_id']}"):
            chosen_id = options[user_choice_display]
            st.session_state['confirmed_ingredient_map'][pending_check['new_name'].strip().lower()] = chosen_id
            if chosen_id == pending_check['candidate_id']:
                 existing = get_ingredient_entity(ingredients_container, chosen_id)
                 if not existing:
                     new_entity_data = IngredientEntity(id=chosen_id, displayName=pending_check['new_name'].strip())
                     saved = upsert_ingredient_entity(ingredients_container, new_entity_data)
                     if not saved: st.error(f"Failed to create master entry for new ingredient: '{pending_check['new_name']}'.")
                     else: logger.info(f"Created new IngredientEntity: {chosen_id}")
                 else: logger.info(f"User chose create new, but ID '{chosen_id}' exists. Using existing.")
            st.session_state['pending_similarity_check'] = None
            st.success(f"Choice confirmed for '{pending_check['new_name']}'. Please click 'Save Recipe' again.")
            st.rerun()

# --- Recipe Input Form ---
form_disabled = st.session_state.get('pending_similarity_check') is not None
with st.form("recipe_form", clear_on_submit=True):
    st.subheader("Recipe Details")
    recipe_title = st.text_input("Recipe Title*", value=current_default_title, key="recipe_title_input", disabled=form_disabled)
    recipe_instructions = st.text_area("Instructions*", value=current_default_instructions, height=300, key="recipe_instructions_input", disabled=form_disabled)

    # --- Other Fields ---
    col_serve, col_time, col_cal = st.columns(3) # Rearranged columns
    with col_serve: num_people = st.number_input("Servings", min_value=1, step=1, value=current_default_num_people, key="num_people", disabled=form_disabled)
    with col_time: total_time = st.number_input("Total Time (min)", min_value=0, step=5, value=current_default_total_time, key="total_time", disabled=form_disabled)
    with col_cal:
        # --- Calories Input ---
        calories = st.number_input("Est. Calories (per serving?)", min_value=0, step=10, value=current_default_calories, key="calories_input", help="Estimated calories, e.g., from import or manual entry.", disabled=form_disabled)
        # --- END Calories Input ---

    col_diff, col_season, col_cat = st.columns(3)
    with col_diff:
        difficulty_options = ["", "Easy", "Medium", "Hard", "Expert"]; difficulty_index = difficulty_options.index(current_default_difficulty) if current_default_difficulty in difficulty_options else 0
        difficulty = st.selectbox("Difficulty", options=difficulty_options, index=difficulty_index, key="difficulty", disabled=form_disabled)
    with col_season:
        season_options = ["", "Any", "Spring", "Summer", "Autumn", "Winter"]; season_index = season_options.index(current_default_season) if current_default_season in season_options else 0
        season = st.selectbox("Best Season", options=season_options, index=season_index, key="season", disabled=form_disabled)
    with col_cat:
        category = st.text_input("Category", value=current_default_category, placeholder="e.g., Primo, Dessert", key="category_input", disabled=form_disabled)

    drink_pairing = st.text_input("Suggested Drink Pairing (Optional)", value=current_default_drink, placeholder="e.g., Chianti Classico", key="drink_input", disabled=form_disabled)

    st.divider()
    st.subheader("Ingredients")
    st.markdown("Enter/Verify each ingredient below. Quantity defaults to 1 if left blank.") # Updated help text

    edited_ingredients_df = st.data_editor(
        st.session_state['manual_ingredients_df'],
        num_rows="dynamic", key="ingredients_editor",
        column_config={
            # Quantity is no longer strictly required here, will default later
            "Quantity": st.column_config.NumberColumn("Qty", help="Numeric quantity (e.g., 100, 0.5, 2). Defaults to 1 if blank.", min_value=0.0, format="%.2f"),
            "Unit": st.column_config.TextColumn("Unit"), # Optional
            "Ingredient Name": st.column_config.TextColumn("Ingredient*", required=True),
            "Notes": st.column_config.TextColumn("Notes")
        }, use_container_width=True, disabled=form_disabled
    )
    st.caption("* Ingredient Name is required.")
    st.divider()
    submitted = st.form_submit_button("💾 Save Recipe", disabled=form_disabled) # Disable button if check pending

# --- Form Submission Logic ---
if submitted and not form_disabled: # Process only if submitted and not disabled
    # Update session state with the final edited ingredients from the editor
    st.session_state['manual_ingredients_df'] = edited_ingredients_df
    st.markdown("--- Processing Submission ---")

    # 1. Retrieve data (including calories)
    title = recipe_title; instructions = recipe_instructions; ingredients_data = edited_ingredients_df.copy()
    num_people_val = int(num_people) if num_people is not None else None; difficulty_val = difficulty if difficulty else None; season_val = season if season else None
    category_val = category.strip() if category else None; total_time_val = int(total_time) if total_time is not None else None; drink_val = drink_pairing.strip() if drink_pairing else None
    calories_val = int(calories) if calories is not None else None # Get calories
    final_image_url = st.session_state.get('imported_image_url')
    # TODO: Handle NEW photo_upload

    # 2. Validation
    validation_ok = True; error_messages = []
    if not title: error_messages.append("Recipe Title is required.")
    if not instructions: error_messages.append("Recipe Instructions are required.")
    ingredients_data.dropna(subset=['Ingredient Name'], inplace=True) # Drop rows if name is missing first
    if ingredients_data.empty: error_messages.append("Please add at least one valid ingredient row (with a name).")
    # Quantity defaults to 1, so no longer strictly required in validation here

    if error_messages:
        validation_ok = False;
        for msg in error_messages: st.error(msg)
        # Store current form values if validation fails
        st.session_state['form_default_title'] = title; st.session_state['form_default_instructions'] = instructions; st.session_state['form_default_num_people'] = num_people
        st.session_state['form_default_total_time'] = total_time; st.session_state['form_default_difficulty'] = difficulty; st.session_state['form_default_season'] = season
        st.session_state['form_default_category'] = category; st.session_state['form_default_drink'] = drink_pairing; st.session_state['form_default_calories'] = calories

    if validation_ok:
        st.success("Input validation passed. Processing ingredients...")
        logger.info(f"Form submitted for recipe: {title}")

        # 3. Process Ingredients (Integrate Similarity Check & Default Quantity)
        try:
            ingredient_items_list: List[IngredientItem] = []
            processed_ingredient_ids = st.session_state.get('confirmed_ingredient_map', {})
            all_ingredients_processed_successfully = True
            needs_similarity_check = None

            with st.spinner("Processing ingredients..."):
                # --- START: Ingredient Processing Logic ---
                for index, row in ingredients_data.iterrows():
                    name = row['Ingredient Name']; qty = row['Quantity']; unit = row['Unit']; notes = row['Notes']
                    if not name or pd.isna(name): continue

                    # --- Default Quantity to 1.0 if missing/NaN ---
                    qty_processed = 1.0 if pd.isna(qty) else float(qty)
                    # --- END Default ---

                    name_lower = name.strip().lower(); confirmed_ingredient_id = None
                    if name_lower in processed_ingredient_ids: confirmed_ingredient_id = processed_ingredient_ids[name_lower]
                    else:
                        ingredient_id_candidate = sanitize_for_id(name)
                        existing_entity = get_ingredient_entity(ingredients_container, ingredient_id_candidate)
                        if existing_entity: confirmed_ingredient_id = existing_entity.id; processed_ingredient_ids[name_lower] = confirmed_ingredient_id
                        else:
                            similar_entities = find_similar_ingredient_display_names(ingredients_container, name.strip())
                            if similar_entities:
                                needs_similarity_check = {"new_name": name.strip(), "candidate_id": ingredient_id_candidate, "similar_entities": similar_entities}
                                st.session_state['pending_similarity_check'] = needs_similarity_check
                                all_ingredients_processed_successfully = False; break
                            else:
                                logger.info(f"No similar ingredients found. Creating new entry for '{name}' with ID '{ingredient_id_candidate}'.")
                                new_entity_data = IngredientEntity(id=ingredient_id_candidate, displayName=name.strip())
                                saved_entity = upsert_ingredient_entity(ingredients_container, new_entity_data)
                                if saved_entity: confirmed_ingredient_id = saved_entity.id; processed_ingredient_ids[name_lower] = confirmed_ingredient_id
                                else: st.error(f"Failed to create master entry for '{name}'."); all_ingredients_processed_successfully = False; break
                    if confirmed_ingredient_id:
                        ingredient_item = IngredientItem(
                            ingredient_id=confirmed_ingredient_id,
                            quantity=qty_processed, # Use the processed quantity
                            unit=str(unit).strip() if pd.notna(unit) else None,
                            notes=str(notes).strip() if pd.notna(notes) else None
                        )
                        ingredient_items_list.append(ingredient_item)
                    elif not needs_similarity_check:
                         st.error(f"Failed to determine ID for ingredient: '{name}'."); all_ingredients_processed_successfully = False; break
                # --- END: Ingredient Processing Logic ---

            if st.session_state.get('pending_similarity_check'):
                 st.warning("Please resolve the ingredient similarity check above before saving.")
                 # Store current form values
                 st.session_state['form_default_title'] = title; st.session_state['form_default_instructions'] = instructions; st.session_state['form_default_num_people'] = num_people
                 st.session_state['form_default_total_time'] = total_time; st.session_state['form_default_difficulty'] = difficulty; st.session_state['form_default_season'] = season
                 st.session_state['form_default_category'] = category; st.session_state['form_default_drink'] = drink_pairing; st.session_state['form_default_calories'] = calories
                 st.rerun() # Rerun to display the prompt

            elif not all_ingredients_processed_successfully:
                 st.error("Recipe saving aborted due to ingredient processing errors.")
            else:
                # --- Proceed to Save Recipe ---
                st.success("All ingredients processed successfully.")
                confirmed_category = category_val
                logger.info(f"Using category: {confirmed_category}")
                logger.info("Creating final Recipe object...")
                try:
                    current_time_utc = datetime.now(timezone.utc)
                    source_type_final = st.session_state.get('original_source_type', 'Manuale')
                    source_url_final = st.session_state.get('original_source_url')

                    new_recipe = Recipe(
                        title=title.strip(), instructions=instructions.strip(), ingredients=ingredient_items_list,
                        category=confirmed_category, num_people=num_people_val, difficulty=difficulty_val,
                        season=season_val, total_time_minutes=total_time_val, drink=drink_val,
                        total_calories_estimated=calories_val, # Save calories
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
                        # Clear state
                        st.session_state['manual_ingredients_df'] = pd.DataFrame([], columns=["Quantity", "Unit", "Ingredient Name", "Notes"])
                        st.session_state['confirmed_ingredient_map'] = {}; st.session_state['imported_image_url'] = None; st.session_state['form_default_title'] = ""; st.session_state['form_default_instructions'] = ""
                        st.session_state['original_source_type'] = 'Manuale'; st.session_state['original_source_url'] = None
                        st.session_state['form_default_num_people'] = None; st.session_state['form_default_total_time'] = None
                        st.session_state['form_default_difficulty'] = ''; st.session_state['form_default_season'] = ''; st.session_state['form_default_category'] = ''; st.session_state['form_default_drink'] = ''; st.session_state['form_default_calories'] = None
                        st.rerun() # Reset form
                    else:
                        st.error("Failed to save recipe. Check logs.")
                        # Store current form values if save fails
                        st.session_state['form_default_title'] = title; st.session_state['form_default_instructions'] = instructions; st.session_state['form_default_num_people'] = num_people
                        st.session_state['form_default_total_time'] = total_time; st.session_state['form_default_difficulty'] = difficulty; st.session_state['form_default_season'] = season
                        st.session_state['form_default_category'] = category; st.session_state['form_default_drink'] = drink_pairing; st.session_state['form_default_calories'] = calories

                except Exception as model_error:
                     st.error(f"Error creating recipe data: {model_error}")
                     logger.error(f"Pydantic/object creation error: {model_error}", exc_info=True)
        except Exception as e:
            st.error(f"An unexpected error occurred: {e}")
            logger.error(f"Error during recipe processing/saving: {e}", exc_info=True)

# --- No Cleanup block needed at the end ---

