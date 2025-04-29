# -*- coding: utf-8 -*-
"""
Streamlit page for manually adding or editing recipes in Mirai Cook.
Handles pre-population of form fields if data is imported from page 3.
Removed ingredient similarity check logic during save.
Includes placeholder for AI food group classification on new ingredients.
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
    # Recipe model now includes 'food_groups' and 'is_verified' on IngredientEntity
    from src.models import Recipe, IngredientItem, IngredientEntity, sanitize_for_id
    from src.persistence import (
       save_recipe,
       get_ingredient_entity,
       # find_similar_ingredient_display_names, # REMOVED
       upsert_ingredient_entity
    )
    from src.azure_clients import (
        SESSION_STATE_RECIPE_CONTAINER,
        SESSION_STATE_INGREDIENT_CONTAINER,
        SESSION_STATE_CLIENTS_INITIALIZED,
        SESSION_STATE_OPENAI_CLIENT # Needed for food group classification
    )
    from src.utils import parse_ingredient_string, parse_servings
    # Import the AI function for food group classification (placeholder)
    # from src.ai_services.genai import classify_ingredient_food_group_openai
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
required_clients = [
    SESSION_STATE_RECIPE_CONTAINER,
    SESSION_STATE_INGREDIENT_CONTAINER,
    SESSION_STATE_OPENAI_CLIENT # Needed for food group
]
clients_ready = True; missing_clients = []
for client_key in required_clients:
    if not st.session_state.get(client_key):
        clients_ready = False; missing_clients.append(client_key.replace("container", "Container Client").replace("_client", " Client"))
if not clients_ready:
    st.error(f"Error: Required Azure connections missing: {', '.join(missing_clients)}.")
    if not st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED): st.warning("Global Azure init reported issues.")
    st.stop()
else:
    recipe_container = st.session_state[SESSION_STATE_RECIPE_CONTAINER]
    ingredients_container = st.session_state[SESSION_STATE_INGREDIENT_CONTAINER]
    openai_client = st.session_state[SESSION_STATE_OPENAI_CLIENT]
    # TODO: Get OpenAI model deployment name for classification from config/env
    openai_classification_model = os.getenv("AZURE_OPENAI_CLASSIFICATION_DEPLOYMENT", "gpt-4o-mini") # Example
    logger.info("Retrieved required Azure clients from session state.")


# --- Initialize Session State Variables ---
default_keys = [
    'form_default_title', 'form_default_instructions', 'form_default_num_people',
    'form_default_total_time', 'imported_image_url', 'original_source_type',
    'original_source_url', #'confirmed_ingredient_map', # REMOVED
    'form_default_difficulty', 'form_default_season', 'form_default_category', 'form_default_drink',
    #'pending_similarity_check', # REMOVED
    'form_default_calories'
]
default_values = ["", "", None, None, None, 'Manuale', None, {}, '', '', '', '', None, None] # Removed defaults for removed state
for key, default_value in zip(default_keys, default_values):
    if key not in st.session_state: st.session_state[key] = default_value
if 'manual_ingredients_df' not in st.session_state:
    st.session_state['manual_ingredients_df'] = pd.DataFrame([], columns=["Quantity", "Unit", "Ingredient Name", "Notes"])


# --- Pre-populate form if data was imported ---
imported_data = st.session_state.get('imported_recipe_data', None)
if imported_data:
    # ... (Pre-population logic remains the same as before) ...
    st.success("Recipe data imported! Please review, structure ingredients if needed, and save.")
    logger.info("Pre-populating form state with imported data.")
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
    try: calories_raw = imported_data.get('calories'); st.session_state['form_default_calories'] = int(calories_raw) if calories_raw is not None else None
    except (ValueError, TypeError): st.session_state['form_default_calories'] = None; logger.warning(f"Could not convert imported calories '{calories_raw}' to integer.")
    parsed_ingredients_list = imported_data.get('parsed_ingredients', [])
    initial_ingredients_df_data = []
    if parsed_ingredients_list:
        for parsed_item in parsed_ingredients_list: initial_ingredients_df_data.append({"Quantity": parsed_item.get("quantity"), "Unit": parsed_item.get("unit", ""), "Ingredient Name": parsed_item.get("name", parsed_item.get("original","")), "Notes": parsed_item.get("notes", "")})
    st.session_state['manual_ingredients_df'] = pd.DataFrame(initial_ingredients_df_data)
    st.session_state['imported_recipe_data'] = None
    logger.info("Cleared imported_recipe_data from session state.")

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
current_default_calories = st.session_state.get('form_default_calories')

# --- Display Imported Image (if available) ---
if current_imported_image_url:
    st.subheader("Imported Image Preview")
    st.image(current_imported_image_url, caption="Image from imported URL/Source", use_container_width=True)
    st.markdown("---")

# --- REMOVED Similarity Check HITL Prompt Section ---

# --- Recipe Input Form ---
# Form is no longer disabled
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
        }, 
        use_container_width=True
    )
    st.caption("* Ingredient Name is required.")
    st.divider()
    submitted = st.form_submit_button("💾 Save Recipe")

# --- Form Submission Logic ---
if submitted:
    st.session_state['manual_ingredients_df'] = edited_ingredients_df
    st.markdown("--- Processing Submission ---")

    # 1. Retrieve data
    title = recipe_title; instructions = recipe_instructions; ingredients_data = edited_ingredients_df.copy()
    num_people_val = int(num_people) if num_people is not None else None; difficulty_val = difficulty if difficulty else None; season_val = season if season else None
    category_val = category.strip() if category else None; total_time_val = int(total_time) if total_time is not None else None; drink_val = drink_pairing.strip() if drink_pairing else None
    calories_val = int(calories) if calories is not None else None
    final_image_url = st.session_state.get('imported_image_url')
    # TODO: Handle NEW photo_upload

    # 2. Validation
    validation_ok = True; error_messages = []
    if not title: error_messages.append("Recipe Title is required.")
    if not instructions: error_messages.append("Recipe Instructions are required.")
    ingredients_data.dropna(subset=['Ingredient Name'], inplace=True)
    if ingredients_data.empty: 
        error_messages.append("Add at least one valid ingredient row (with name).")
    # Quantity defaults to 1, no longer strictly required in validation

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

        # 3. Process Ingredients (Simplified: Exact Match or Create New with AI Food Group)
        try:
            ingredient_items_list: List[IngredientItem] = []
            # Removed processed_ingredient_ids cache as HITL is removed
            all_ingredients_processed_successfully = True
            recipe_food_groups = set() # To collect unique food groups for the recipe

            with st.spinner("Processing ingredients and classifying food groups..."):
                # --- START: Simplified Ingredient Processing ---
                for index, row in ingredients_data.iterrows():
                    name = row['Ingredient Name']; qty = row['Quantity']; unit = row['Unit']; notes = row['Notes']
                    if not name or pd.isna(name): continue
                    qty_processed = 1.0 if pd.isna(qty) else float(qty) # Default quantity

                    ingredient_id = None # Reset for each row
                    ingredient_entity = None # Store the found/created entity
                    ingredient_id_candidate = sanitize_for_id(name.strip())

                    # Check exact match
                    existing_entity = get_ingredient_entity(ingredients_container, ingredient_id_candidate)

                    if existing_entity:
                        ingredient_id = existing_entity.id
                        ingredient_entity = existing_entity # Use existing entity
                        logger.info(f"Exact match found for '{name}'. Using ID: {ingredient_id}")
                    else:
                        # Create new IngredientEntity
                        logger.info(f"No exact match for '{name}'. Creating new IngredientEntity with ID '{ingredient_id_candidate}'.")
                        # --- Call AI to classify food_group ---
                        predicted_food_group = None
                        try:
                            # Assuming classify_ingredient_food_group_openai exists in genai.py
                            from src.ai_services.genai import classify_ingredient_food_group_openai
                            if openai_client:
                                predicted_food_group = classify_ingredient_food_group_openai(openai_client, name.strip(), openai_classification_model)
                                logger.info(f"OpenAI suggested food group '{predicted_food_group}' for '{name}'")
                            else:
                                logger.warning("OpenAI client not available for food group classification.")
                        except Exception as ai_error:
                            logger.error(f"Error classifying food group for '{name}': {ai_error}")
                        # ---------------------------------------
                        new_entity_data = IngredientEntity(
                            id=ingredient_id_candidate,
                            displayName=name.strip(),
                            food_group=predicted_food_group, # Assign classified group
                            is_verified=False # Mark as unverified
                        )
                        saved_entity = upsert_ingredient_entity(ingredients_container, new_entity_data)
                        if saved_entity:
                            ingredient_id = saved_entity.id
                            ingredient_entity = saved_entity # Use the newly saved entity
                            logger.info(f"Created new IngredientEntity: {ingredient_id}")
                        else:
                            st.error(f"Failed to create master entry for ingredient: '{name}'.")
                            all_ingredients_processed_successfully = False; break

                    if ingredient_id and ingredient_entity:
                        # Add food group to recipe's set
                        if ingredient_entity.food_group:
                            recipe_food_groups.add(ingredient_entity.food_group)
                        # Create IngredientItem
                        ingredient_item = IngredientItem(
                            ingredient_id=ingredient_id,
                            quantity=qty_processed,
                            unit=str(unit).strip() if pd.notna(unit) else None,
                            notes=str(notes).strip() if pd.notna(notes) else None
                        )
                        ingredient_items_list.append(ingredient_item)
                    else: # Should not happen if creation logic is correct
                        st.error(f"Failed to obtain valid ID or Entity for ingredient: '{name}'.")
                        all_ingredients_processed_successfully = False; break
                # --- END: Simplified Ingredient Processing ---

            if not all_ingredients_processed_successfully:
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
                        total_calories_estimated=calories_val,
                        source_type=source_type_final, source_url=source_url_final, image_url=final_image_url,
                        created_at=current_time_utc, updated_at=current_time_utc,
                        food_groups=sorted(list(recipe_food_groups)) # Assign collected food groups
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
                        # st.session_state['confirmed_ingredient_map'] = {} # No longer needed
                        st.session_state['imported_image_url'] = None; st.session_state['form_default_title'] = ""; st.session_state['form_default_instructions'] = ""
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

