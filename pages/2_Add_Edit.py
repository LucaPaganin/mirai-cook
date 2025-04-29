# -*- coding: utf-8 -*-
"""
Streamlit page for manually adding or editing recipes in Mirai Cook.
Refactored UI into functions. Handles pre-population.
Removed form disabling during similarity check.
"""

import streamlit as st
import pandas as pd
from datetime import datetime, timezone
import logging
import sys
import os
from typing import List, Optional, Dict, Any

# --- Setup Project Root Path ---
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if project_root not in sys.path: sys.path.insert(0, project_root)

# --- Import Application Modules ---
try:
    from src.models import Recipe, IngredientItem, IngredientEntity, sanitize_for_id
    from src.persistence import (
       save_recipe, get_ingredient_entity,
       upsert_ingredient_entity
    )
    from src.azure_clients import (
        SESSION_STATE_RECIPE_CONTAINER, SESSION_STATE_INGREDIENT_CONTAINER,
        SESSION_STATE_CLIENTS_INITIALIZED, SESSION_STATE_OPENAI_CLIENT
    )
    from src.utils import parse_ingredient_string, parse_servings
    # from src.ai_services.genai import classify_ingredient_food_group_openai # Import when ready
except ImportError as e:
    st.error(f"Error importing application modules: {e}. Check PYTHONPATH.")
    st.stop()

# --- Configure Logging ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Page Configuration ---
st.set_page_config(page_title="Add/Edit Recipe - Mirai Cook", page_icon="✍️")

# --- Helper Functions for UI Sections ---

def initialize_page_state():
    """Initializes necessary session state keys for this page."""
    default_keys = [
        'form_default_title', 'form_default_instructions', 'form_default_num_people',
        'form_default_total_time', 'imported_image_url', 'original_source_type',
        'original_source_url', 'confirmed_ingredient_map', 'form_default_difficulty',
        'form_default_season', 'form_default_category', 'form_default_drink',
        'pending_similarity_check', 'form_default_calories'
    ]
    default_values = ["", "", None, None, None, 'Manuale', None, {}, '', '', '', '', None, None]
    for key, default_value in zip(default_keys, default_values):
        if key not in st.session_state: st.session_state[key] = default_value
    if 'manual_ingredients_df' not in st.session_state:
        st.session_state['manual_ingredients_df'] = pd.DataFrame([], columns=["Quantity", "Unit", "Ingredient Name", "Notes"])

def check_azure_clients() -> bool:
    """Checks if required Azure clients are initialized in session state."""
    required_clients = [SESSION_STATE_RECIPE_CONTAINER, SESSION_STATE_INGREDIENT_CONTAINER, SESSION_STATE_OPENAI_CLIENT]
    missing_clients = [key.replace("container", "Cont.").replace("_client", "Client")
                       for key in required_clients if not st.session_state.get(key)]
    if missing_clients:
        st.error(f"Error: Required connections missing: {', '.join(missing_clients)}.")
        if not st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED): st.warning("Global Azure init reported issues.")
        return False
    logger.info("Retrieved required Azure clients from session state.")
    return True

def pre_populate_from_import():
    """Checks for imported data in session state and sets defaults."""
    imported_data = st.session_state.get('imported_recipe_data', None)
    if imported_data:
        st.success("Recipe data imported! Please review, structure ingredients if needed, and save.")
        logger.info("Pre-populating form state with imported data.")
        st.session_state['form_default_title'] = imported_data.get('title', '')
        st.session_state['form_default_instructions'] = imported_data.get('instructions_text', '')
        st.session_state['imported_image_url'] = imported_data.get('image_url')
        st.session_state['original_source_type'] = imported_data.get('source_type', 'Imported')
        st.session_state['original_source_url'] = imported_data.get('source_url')
        st.session_state['form_default_num_people'] = parse_servings(imported_data.get('yields'))
        try: total_time_raw = imported_data.get('total_time'); st.session_state['form_default_total_time'] = int(total_time_raw) if total_time_raw is not None else None
        except: st.session_state['form_default_total_time'] = None
        st.session_state['form_default_category'] = imported_data.get('category', '')
        st.session_state['form_default_drink'] = imported_data.get('drink', '')
        try: calories_raw = imported_data.get('calories'); st.session_state['form_default_calories'] = int(calories_raw) if calories_raw is not None else None
        except: st.session_state['form_default_calories'] = None

        parsed_ingredients_list = imported_data.get('parsed_ingredients', [])
        initial_ingredients_df_data = []
        if parsed_ingredients_list:
            for item in parsed_ingredients_list: initial_ingredients_df_data.append({"Quantity": item.get("quantity"), "Unit": item.get("unit", ""), "Ingredient Name": item.get("name", item.get("original","")), "Notes": item.get("notes", "")})
        st.session_state['manual_ingredients_df'] = pd.DataFrame(initial_ingredients_df_data)
        st.session_state['imported_recipe_data'] = None # Clear after processing
        logger.info("Cleared imported_recipe_data from session state.")
        # Consider if rerun is still needed or if defaults are picked up correctly
        # st.rerun() # Maybe not needed if widgets read state correctly

def render_similarity_prompt(ingredients_container) -> bool:
    """Renders the HITL prompt for similar ingredients if pending."""
    pending_check = st.session_state.get('pending_similarity_check')
    if pending_check:
        st.warning(f"Potential duplicate found for: **{pending_check['new_name']}**")
        st.write("Similar existing ingredient(s):")
        options = {}
        for entity in pending_check['similar_entities']:
            option_text = f"Use existing: '{entity.displayName}' (ID: {entity.id})"
            options[option_text] = entity.id
        create_new_option = f"Create NEW entry for: '{pending_check['new_name']}' (ID: {pending_check['candidate_id']})"
        options[create_new_option] = pending_check['candidate_id']

        user_choice_display = st.radio("Select an action:", options=list(options.keys()), key=f"similarity_choice_{pending_check['candidate_id']}", index=0)

        if st.button("Confirm Ingredient Choice", key=f"confirm_similarity_{pending_check['candidate_id']}"):
            chosen_id = options[user_choice_display]
            st.session_state['confirmed_ingredient_map'][pending_check['new_name'].strip().lower()] = chosen_id
            if chosen_id == pending_check['candidate_id']:
                 existing = get_ingredient_entity(ingredients_container, chosen_id)
                 if not existing:
                     logger.info(f"User chose create new. Creating IngredientEntity '{pending_check['new_name']}' (ID: {chosen_id})")
                     # --- TODO: Call AI for food_group classification here ---
                     predicted_food_group = None # Placeholder
                     new_entity_data = IngredientEntity(id=chosen_id, displayName=pending_check['new_name'].strip(), food_group=predicted_food_group, is_verified=False)
                     saved = upsert_ingredient_entity(ingredients_container, new_entity_data)
                     if not saved: st.error(f"Failed to create master entry for '{pending_check['new_name']}'.")
                     else: logger.info(f"Created new IngredientEntity: {chosen_id}")
                 else: logger.info(f"User chose create new, but ID '{chosen_id}' exists. Using existing.")
            st.session_state['pending_similarity_check'] = None
            st.success(f"Choice confirmed for '{pending_check['new_name']}'. Please click 'Save Recipe' again.")
            st.rerun() # Rerun to remove prompt and enable form
        return True # Indicate that a check was displayed
    return False # No check was displayed

def render_recipe_form() -> Optional[Dict[str, Any]]:
    """Renders the main recipe input form and returns data on submission."""
    # Retrieve default values from session state for rendering
    default_title = st.session_state.get('form_default_title', "")
    default_instructions = st.session_state.get('form_default_instructions', "")
    default_num_people = st.session_state.get('form_default_num_people')
    default_total_time = st.session_state.get('form_default_total_time')
    default_difficulty = st.session_state.get('form_default_difficulty', '')
    default_season = st.session_state.get('form_default_season', '')
    default_category = st.session_state.get('form_default_category', '')
    default_drink = st.session_state.get('form_default_drink', '')
    default_calories = st.session_state.get('form_default_calories')

    submitted_data = None
    with st.form("recipe_form", clear_on_submit=True):
        st.subheader("Recipe Details")
        recipe_title = st.text_input("Recipe Title*", value=default_title, key="recipe_title_input")
        recipe_instructions = st.text_area("Instructions*", value=default_instructions, height=300, key="recipe_instructions_input")

        col1, col2, col3 = st.columns(3);
        with col1: num_people = st.number_input("Servings (People)", min_value=1, step=1, value=default_num_people, key="num_people")
        with col2: difficulty_options = ["", "Easy", "Medium", "Hard", "Expert"]; difficulty_index = difficulty_options.index(default_difficulty) if default_difficulty in difficulty_options else 0; difficulty = st.selectbox("Difficulty", options=difficulty_options, index=difficulty_index, key="difficulty")
        with col3: season_options = ["", "Any", "Spring", "Summer", "Autumn", "Winter"]; season_index = season_options.index(default_season) if default_season in season_options else 0; season = st.selectbox("Best Season", options=season_options, index=season_index, key="season")
        total_time = st.number_input("Total Time (prep + cook, minutes)", min_value=0, step=5, value=default_total_time, key="total_time")
        category = st.text_input("Category", value=default_category, placeholder="e.g., Primo, Dessert", key="category_input")
        drink_pairing = st.text_input("Suggested Drink Pairing (Optional)", value=default_drink, placeholder="e.g., Chianti Classico", key="drink_input")
        calories = st.number_input("Est. Calories (per serving?)", min_value=0, step=10, value=default_calories, key="calories_input", help="Estimated calories, e.g., from import or manual entry.")

        # Submit button inside the form
        submitted = st.form_submit_button("💾 Process & Save Recipe")
        if submitted:
            # Package form data for processing
            submitted_data = {
                "title": recipe_title,
                "instructions": recipe_instructions,
                "num_people": num_people,
                "difficulty": difficulty,
                "season": season,
                "total_time": total_time,
                "category": category,
                "drink_pairing": drink_pairing,
                "calories": calories
            }
    return submitted_data # Returns data dict only when submitted

def render_ingredients_editor():
    """Renders the ingredient data editor."""
    st.divider()
    st.subheader("Ingredients")
    st.markdown("Enter/Verify each ingredient below. Quantity defaults to 1 if left blank.")
    edited_ingredients_df = st.data_editor(
        st.session_state['manual_ingredients_df'],
        num_rows="dynamic", key="ingredients_editor",
        column_config={
            "Quantity": st.column_config.NumberColumn("Qty", help="Defaults to 1 if blank.", min_value=0.0, format="%.2f"),
            "Unit": st.column_config.TextColumn("Unit"), # Optional
            "Ingredient Name": st.column_config.TextColumn("Ingredient*", required=True),
            "Notes": st.column_config.TextColumn("Notes")
        }, use_container_width=True
    )
    st.caption("* Ingredient Name is required.")
    # Store edits back to session state immediately so they are available when form is submitted
    st.session_state['manual_ingredients_df'] = edited_ingredients_df


def process_and_save_recipe(form_data: Dict[str, Any], ingredients_df: pd.DataFrame, recipe_container, ingredients_container, openai_client, openai_model_name):
    """Processes ingredients, creates Recipe object, and saves to DB."""
    st.markdown("--- Processing Submission ---")
    # 1. Retrieve data from inputs
    title = form_data["title"]; instructions = form_data["instructions"]
    ingredients_data = ingredients_df.copy()
    num_people_val = int(form_data["num_people"]) if form_data["num_people"] is not None else None
    difficulty_val = form_data["difficulty"] if form_data["difficulty"] else None
    season_val = form_data["season"] if form_data["season"] else None
    category_val = form_data["category"].strip() if form_data["category"] else None
    total_time_val = int(form_data["total_time"]) if form_data["total_time"] is not None else None
    drink_val = form_data["drink_pairing"].strip() if form_data["drink_pairing"] else None
    calories_val = int(form_data["calories"]) if form_data["calories"] is not None else None
    final_image_url = st.session_state.get('imported_image_url')
    # TODO: Handle NEW photo_upload

    # 2. Validation
    validation_ok = True
    error_messages = []
    if not title: 
        error_messages.append("Recipe Title is required.")
    if not instructions: 
        error_messages.append("Recipe Instructions are required.")
    ingredients_data.dropna(subset=['Ingredient Name'], inplace=True)
    if ingredients_data.empty: 
        error_messages.append("Add at least one valid ingredient row (with name).")
    # Quantity defaults to 1, no longer strictly required in validation

    if error_messages:
        validation_ok = False
        for msg in error_messages: st.error(msg)
        # Store current form values if validation fails (using input dict)
        st.session_state['form_default_title'] = title
        st.session_state['form_default_instructions'] = instructions
        st.session_state['form_default_num_people'] = form_data["num_people"]
        st.session_state['form_default_total_time'] = form_data["total_time"]
        st.session_state['form_default_difficulty'] = form_data["difficulty"]
        st.session_state['form_default_season'] = form_data["season"]
        st.session_state['form_default_category'] = form_data["category"]
        st.session_state['form_default_drink'] = form_data["drink_pairing"]
        st.session_state['form_default_calories'] = form_data["calories"]

    if validation_ok:
        st.success("Input validation passed. Processing ingredients...")
        logger.info(f"Processing validated form data for recipe: {title}")

        # 3. Process Ingredients
        try:
            ingredient_items_list: List[IngredientItem] = []
            processed_ingredient_ids = st.session_state.get('confirmed_ingredient_map', {})
            all_ingredients_processed_successfully = True
            needs_similarity_check = None

            with st.spinner("Processing ingredients..."):
                # --- START: Simplified Ingredient Processing ---
                for index, row in ingredients_data.iterrows():
                    name = row['Ingredient Name']; qty = row['Quantity']; unit = row['Unit']; notes = row['Notes']
                    if not name or pd.isna(name): 
                        continue
                    qty_processed = 1.0 if pd.isna(qty) else float(qty) # Default quantity
                    name_lower = name.strip().lower()
                    confirmed_ingredient_id = None

                    if name_lower in processed_ingredient_ids:
                        confirmed_ingredient_id = processed_ingredient_ids[name_lower]
                    else:
                        ingredient_id_candidate = sanitize_for_id(name.strip())
                        existing_entity = get_ingredient_entity(ingredients_container, ingredient_id_candidate)
                        if existing_entity:
                            confirmed_ingredient_id = existing_entity.id
                            processed_ingredient_ids[name_lower] = confirmed_ingredient_id
                        else:
                            # --- Similarity Check Trigger ---
                            similar_entities = find_similar_ingredient_display_names(ingredients_container, name.strip())
                            if similar_entities:
                                needs_similarity_check = {"new_name": name.strip(), "candidate_id": ingredient_id_candidate, "similar_entities": similar_entities}
                                st.session_state['pending_similarity_check'] = needs_similarity_check
                                all_ingredients_processed_successfully = False; break # Stop processing to show prompt
                            else:
                                # Create new IngredientEntity if no exact or similar found
                                logger.info(f"No similar ingredients found. Creating new entry for '{name}' with ID '{ingredient_id_candidate}'.")
                                # --- TODO: Call AI to classify food_group ---
                                predicted_food_group = None # Placeholder
                                # try:
                                #     from src.ai_services.genai import classify_ingredient_food_group_openai
                                #     predicted_food_group = classify_ingredient_food_group_openai(openai_client, name.strip(), openai_model_name)
                                # except Exception as ai_err: logger.error(f"Food group classification failed: {ai_err}")

                                new_entity_data = IngredientEntity(id=ingredient_id_candidate, displayName=name.strip(), food_group=predicted_food_group, is_verified=False)
                                saved_entity = upsert_ingredient_entity(ingredients_container, new_entity_data)
                                if saved_entity: confirmed_ingredient_id = saved_entity.id; processed_ingredient_ids[name_lower] = confirmed_ingredient_id
                                else: st.error(f"Failed to create master entry for '{name}'."); all_ingredients_processed_successfully = False; break

                    if confirmed_ingredient_id:
                        ingredient_item = IngredientItem(ingredient_id=confirmed_ingredient_id, quantity=qty_processed, unit=str(unit).strip() if pd.notna(unit) else None, notes=str(notes).strip() if pd.notna(notes) else None)
                        ingredient_items_list.append(ingredient_item)
                    elif not needs_similarity_check: # Error only if not stopped for similarity check
                        st.error(f"Failed to determine ID for ingredient: '{name}'."); all_ingredients_processed_successfully = False; break
                # --- END: Simplified Ingredient Processing ---

            # Check if we need to pause for user input on similarity
            if st.session_state.get('pending_similarity_check'):
                 st.warning("Please resolve the ingredient similarity check above before saving.")
                 # Store current form values so they are not lost on rerun
                 st.session_state['form_default_title'] = title; st.session_state['form_default_instructions'] = instructions; st.session_state['form_default_num_people'] = form_data["num_people"]
                 st.session_state['form_default_total_time'] = form_data["total_time"]; st.session_state['form_default_difficulty'] = form_data["difficulty"]; st.session_state['form_default_season'] = form_data["season"]
                 st.session_state['form_default_category'] = form_data["category"]; st.session_state['form_default_drink'] = form_data["drink_pairing"]; st.session_state['form_default_calories'] = form_data["calories"]
                 st.rerun() # Rerun to display the prompt

            elif not all_ingredients_processed_successfully:
                 st.error("Recipe saving aborted due to ingredient processing errors.")
            else:
                # --- Proceed to Save Recipe ---
                st.success("All ingredients processed successfully.")
                confirmed_category = category_val # Use value from text input
                logger.info(f"Using category: {confirmed_category}")
                logger.info("Creating final Recipe object...")
                try:
                    current_time_utc = datetime.now(timezone.utc)
                    source_type_final = st.session_state.get('original_source_type', 'Manuale')
                    source_url_final = st.session_state.get('original_source_url')
                    # Calculate food_groups for the recipe
                    recipe_food_groups = set()
                    for item in ingredient_items_list:
                        entity = get_ingredient_entity(ingredients_container, item.ingredient_id)
                        if entity and entity.food_group: recipe_food_groups.add(entity.food_group)

                    new_recipe = Recipe(
                        title=title.strip(), instructions=instructions.strip(), ingredients=ingredient_items_list,
                        category=confirmed_category, num_people=num_people_val, difficulty=difficulty_val,
                        season=season_val, total_time_minutes=total_time_val, drink=drink_val,
                        total_calories_estimated=calories_val, source_type=source_type_final,
                        source_url=source_url_final, image_url=final_image_url,
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
                        st.session_state['confirmed_ingredient_map'] = {}
                        st.session_state['imported_image_url'] = None; st.session_state['form_default_title'] = ""; st.session_state['form_default_instructions'] = ""
                        st.session_state['original_source_type'] = 'Manuale'; st.session_state['original_source_url'] = None
                        st.session_state['form_default_num_people'] = None; st.session_state['form_default_total_time'] = None
                        st.session_state['form_default_difficulty'] = ''; st.session_state['form_default_season'] = ''; st.session_state['form_default_category'] = ''; st.session_state['form_default_drink'] = ''; st.session_state['form_default_calories'] = None
                        st.rerun() # Reset form
                    else:
                        st.error("Failed to save recipe. Check logs.")
                        # Store current form values if save fails
                        st.session_state['form_default_title'] = title; st.session_state['form_default_instructions'] = instructions; st.session_state['form_default_num_people'] = form_data["num_people"]
                        st.session_state['form_default_total_time'] = form_data["total_time"]; st.session_state['form_default_difficulty'] = form_data["difficulty"]; st.session_state['form_default_season'] = form_data["season"]
                        st.session_state['form_default_category'] = form_data["category"]; st.session_state['form_default_drink'] = form_data["drink_pairing"]; st.session_state['form_default_calories'] = form_data["calories"]

                except Exception as model_error:
                     st.error(f"Error creating recipe data: {model_error}")
                     logger.error(f"Pydantic/object creation error: {model_error}", exc_info=True)
        except Exception as e:
            st.error(f"An unexpected error occurred: {e}")
            logger.error(f"Error during recipe processing/saving: {e}", exc_info=True)


# --- Main Page Logic ---
initialize_page_state()
if check_azure_clients():
    # Retrieve necessary clients for this page
    recipe_container = st.session_state[SESSION_STATE_RECIPE_CONTAINER]
    ingredients_container = st.session_state[SESSION_STATE_INGREDIENT_CONTAINER]
    openai_client = st.session_state[SESSION_STATE_OPENAI_CLIENT]
    openai_model_name = os.getenv("AZURE_OPENAI_CLASSIFICATION_DEPLOYMENT", "gpt-4o-mini")

    # Handle pre-population from import page if needed
    pre_populate_from_import()

    # Display HITL prompt if needed (outside the form)
    similarity_check_pending = render_similarity_prompt(ingredients_container)

    # Display ingredients editor (outside the form to allow interaction during HITL)
    render_ingredients_editor()

    # Display the main form (returns data only on submit)
    # Pass necessary clients/config to the processing function if needed inside
    submitted_form_data = render_recipe_form()

    # Process form submission if data was submitted AND no similarity check is pending
    if submitted_form_data and not similarity_check_pending:
        final_ingredients_df = st.session_state['manual_ingredients_df'] # Get latest edits
        process_and_save_recipe(
            submitted_form_data,
            final_ingredients_df,
            recipe_container,
            ingredients_container,
            openai_client,
            openai_model_name
        )

