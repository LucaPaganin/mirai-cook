# -*- coding: utf-8 -*-
"""
Streamlit page for manually adding or editing recipes in Mirai Cook.
Focuses on the UI structure and basic form submission flow.
Includes fields for difficulty, servings, and season.
Includes improved check for necessary Azure clients.
"""

import streamlit as st
import pandas as pd # Required for st.data_editor
from datetime import datetime, timezone # Use timezone-aware datetime
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
    from src.models import Recipe, IngredientItem, IngredientEntity, sanitize_for_id
    from src.persistence import (
       save_recipe,
       get_ingredient_entity,
       find_similar_ingredient_display_names,
       upsert_ingredient_entity
    )
    # Import session state keys for clients
    from src.azure_clients import (
        SESSION_STATE_RECIPE_CONTAINER,
        SESSION_STATE_INGREDIENT_CONTAINER,
        SESSION_STATE_CLIENTS_INITIALIZED,
        # SESSION_STATE_LANGUAGE_CLIENT # Uncomment when needed for category
    )
    # from src.ai_services import get_category_suggestion # Uncomment when implemented
except ImportError as e:
    st.error(f"Error importing application modules: {e}. Check PYTHONPATH and module locations.")
    st.stop()

# --- Configure Logging ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Page Configuration ---
try:
    st.set_page_config(
        page_title="Add/Edit Recipe - Mirai Cook",
        page_icon="✍️"
    )
except st.errors.StreamlitAPIException:
    # Config already set, ignore
    pass

st.title("✍️ Add / Edit Recipe")
st.markdown("Manually add a new recipe to your Mirai Cook cookbook.")

# --- Check if NECESSARY Azure Clients are Initialized ---
# Check specifically for the clients required by *this page*
required_clients = [SESSION_STATE_RECIPE_CONTAINER, SESSION_STATE_INGREDIENT_CONTAINER]
clients_ready = True
missing_clients = []

for client_key in required_clients:
    if not st.session_state.get(client_key):
        clients_ready = False
        missing_clients.append(client_key.replace("container", "Container Client")) # Make name readable

if not clients_ready:
    st.error(f"Error: The following required Azure connections are missing: {', '.join(missing_clients)}. Please ensure Azure services were initialized correctly (check main page logs or configuration).")
    logger.error(f"Add/Edit page stopped. Missing clients in session state: {', '.join(missing_clients)}")
    # Optionally check the global flag too for a general warning
    if not st.session_state.get(SESSION_STATE_CLIENTS_INITIALIZED):
         st.warning("Note: Global Azure client initialization reported issues.")
    st.stop() # Stop execution if essential clients are missing
else:
    # Retrieve necessary container clients from session state
    recipe_container = st.session_state[SESSION_STATE_RECIPE_CONTAINER]
    ingredients_container = st.session_state[SESSION_STATE_INGREDIENT_CONTAINER]
    logger.info("Successfully retrieved required Cosmos DB container clients from session state for Add/Edit page.")


# --- Initialize Session State for Ingredient Editor ---
# Ensures the editor doesn't lose data on reruns before form submission
if 'manual_ingredients_df' not in st.session_state:
    st.session_state['manual_ingredients_df'] = pd.DataFrame(
        [],
        columns=["Quantity", "Unit", "Ingredient Name", "Notes"]
    )
if 'confirmed_ingredient_map' not in st.session_state:
   # This might be used later to store results of similarity checks/HITL
   st.session_state['confirmed_ingredient_map'] = {}


# --- Recipe Input Form ---
with st.form("recipe_form", clear_on_submit=True): # Clear form on successful submission
    st.subheader("Recipe Details")

    recipe_title = st.text_input("Recipe Title*", placeholder="E.g., Pasta al Pesto Genovese")
    recipe_instructions = st.text_area("Instructions*", height=300, placeholder="Describe the preparation steps...")

    # --- NEW FIELDS WIDGETS ---
    col1, col2, col3 = st.columns(3)
    with col1:
        num_people = st.number_input("Servings (People)", min_value=1, step=1, value=None, key="num_people", help="How many people does this recipe serve?")
    with col2:
        # Using selectbox for predefined difficulty
        difficulty_options = ["", "Easy", "Medium", "Hard", "Expert"] # Added Expert
        difficulty = st.selectbox("Difficulty", options=difficulty_options, index=0, key="difficulty", help="Select the estimated difficulty.")
    with col3:
        # Using selectbox for season
        season_options = ["", "Any", "Spring", "Summer", "Autumn", "Winter"]
        season = st.selectbox("Best Season", options=season_options, index=0, key="season", help="Select the best season for this recipe.")
    # --- END NEW FIELDS WIDGETS ---

    # Optional fields
    col_prep, col_cook = st.columns(2)
    with col_prep:
        prep_time = st.number_input("Prep Time (minutes)", min_value=0, step=5, value=None, key="prep_time")
    with col_cook:
        cook_time = st.number_input("Cook Time (minutes)", min_value=0, step=5, value=None, key="cook_time")

    st.divider()

    st.subheader("Ingredients")
    st.markdown("Enter each ingredient below. Double-click a cell to edit.")

    # Use st.data_editor for structured ingredient input
    edited_ingredients_df = st.data_editor(
        st.session_state['manual_ingredients_df'],
        num_rows="dynamic", # Allow adding/deleting rows
        key="ingredients_editor",
        column_config={
            "Quantity": st.column_config.NumberColumn("Qty", help="Numeric quantity (e.g., 100, 0.5, 2)", min_value=0.0, format="%.2f"),
            "Unit": st.column_config.TextColumn("Unit", help="Unit of measure (e.g., g, ml, tsp, tbsp, piece, q.b.)"),
            "Ingredient Name": st.column_config.TextColumn("Ingredient*", help="Name of the ingredient (e.g., Basil, Pine Nuts)", required=True),
            "Notes": st.column_config.TextColumn("Notes", help="Optional notes (e.g., finely chopped)")
        },
        use_container_width=True
    )
    # Update session state immediately to reflect edits in the data editor
    st.session_state['manual_ingredients_df'] = edited_ingredients_df

    st.caption("* Ingredient Name is required.")

    st.divider()

    st.markdown("**Category:** (Automatic suggestion and selection to be added)")
    # Example: Manual selection for now
    portata_category_manual = st.selectbox("Recipe Category (Manual)", ["", "Antipasto", "Primo", "Secondo", "Contorno", "Dolce", "Piatto Unico", "Altro"], index=0, placeholder="Select category...", key="porta_cat")


    st.divider()

    # Submit Button
    submitted = st.form_submit_button("💾 Save Recipe")

# --- Form Submission Logic ---
if submitted:
    # Persist the latest edits from the data editor before processing
    st.session_state['manual_ingredients_df'] = edited_ingredients_df

    st.markdown("--- Processing Submission ---")

    # 1. Retrieve data from form widgets
    title = recipe_title
    instructions = recipe_instructions
    ingredients_data = edited_ingredients_df.copy() # Work on a copy
    # Retrieve new fields, handle empty selection from selectbox (returns "")
    num_people_val = int(num_people) if num_people is not None else None
    difficulty_val = difficulty if difficulty else None # Store None if empty string selected
    season_val = season if season else None # Store None if empty string selected
    portata_category_val = portata_category_manual if portata_category_manual else None # Store None if empty string selected
    prep_time_val = int(prep_time) if prep_time is not None else None
    cook_time_val = int(cook_time) if cook_time is not None else None


    # 2. Basic Validation
    validation_ok = True
    error_messages = []
    if not title:
        error_messages.append("Recipe Title is required.")
        validation_ok = False
    if not instructions:
        error_messages.append("Recipe Instructions are required.")
        validation_ok = False
    # Filter out rows where ingredient name is missing before validation/processing
    valid_ingredients_data = ingredients_data.dropna(subset=['Ingredient Name'])
    if valid_ingredients_data.empty:
         error_messages.append("Please add at least one ingredient with a name.")
         validation_ok = False
    elif len(valid_ingredients_data) < len(ingredients_data):
         st.warning("Rows with missing Ingredient Name were ignored.")
         ingredients_data = valid_ingredients_data # Process only valid rows

    if not validation_ok:
        for msg in error_messages:
            st.error(msg)
    else:
        st.success("Basic validation passed. Processing ingredients...")
        logger.info(f"Form submitted for recipe: {title}")

        # 3. Process Ingredients & Prepare Recipe Object
        try:
            ingredient_items_list: List[IngredientItem] = []
            processed_ingredient_ids = {} # Cache results {name_lower: confirmed_id}
            all_ingredients_processed_successfully = True

            with st.spinner("Processing ingredients and checking master list..."):
                # --- IMPLEMENT INGREDIENT PROCESSING LOGIC ---
                # Iterate through rows of the ingredients_data DataFrame:
                for index, row in ingredients_data.iterrows():
                    name = row['Ingredient Name']
                    qty = row['Quantity']
                    unit = row['Unit']
                    notes = row['Notes']

                    if not name or pd.isna(name): continue # Should be filtered already

                    name_lower = name.strip().lower()
                    confirmed_ingredient_id = None

                    # Check cache first
                    if name_lower in processed_ingredient_ids:
                        confirmed_ingredient_id = processed_ingredient_ids[name_lower]
                        logger.info(f"Using cached ID '{confirmed_ingredient_id}' for ingredient '{name}'")
                    else:
                        # a. Sanitize name
                        ingredient_id_candidate = sanitize_for_id(name)
                        # b. Check exact match
                        existing_entity = get_ingredient_entity(ingredients_container, ingredient_id_candidate)
                        if existing_entity:
                            confirmed_ingredient_id = existing_entity.id
                            logger.info(f"Exact match found for '{name}'. Using ID: {confirmed_ingredient_id}")
                        else:
                            # c/d. Check similarity & Create if needed (Simplified - No HITL Prompt Here Yet)
                            # TODO: Implement similarity check + HITL prompt using st.radio/selectbox outside the form or via state management
                            logger.warning(f"No exact match for '{name}'. Similarity check/HITL needed. Creating new entry for now.")
                            new_entity_data = IngredientEntity(id=ingredient_id_candidate, displayName=name.strip())
                            saved_entity = upsert_ingredient_entity(ingredients_container, new_entity_data)
                            if saved_entity:
                                confirmed_ingredient_id = saved_entity.id
                                logger.info(f"Created new IngredientEntity: {confirmed_ingredient_id}")
                                # TODO: Potentially trigger calorie lookup here or later async
                            else:
                                st.error(f"Failed to create master entry for ingredient: '{name}'.")
                                all_ingredients_processed_successfully = False
                                break # Stop processing

                        if confirmed_ingredient_id:
                             processed_ingredient_ids[name_lower] = confirmed_ingredient_id
                        else:
                             st.error(f"Failed to determine a valid ID for ingredient: '{name}'.")
                             all_ingredients_processed_successfully = False
                             break

                    # e. Create IngredientItem if ID confirmed
                    if confirmed_ingredient_id:
                        ingredient_item = IngredientItem(
                            ingredient_id=confirmed_ingredient_id,
                            quantity=float(qty) if pd.notna(qty) else None,
                            unit=str(unit).strip() if pd.notna(unit) else None,
                            notes=str(notes).strip() if pd.notna(notes) else None
                        )
                        ingredient_items_list.append(ingredient_item)
                # --- End of Ingredient Loop ---

            if not all_ingredients_processed_successfully:
                 st.error("Recipe saving aborted due to errors processing ingredients.")
            else:
                st.success("All ingredients processed.")
                logger.info("Ingredient processing complete.")

                # 4. Get Category (Using manual selection for now)
                # TODO: Replace with AI suggestion + HITL later
                confirmed_category = portata_category_val # Get value from the selectbox
                logger.info(f"Using category: {confirmed_category}")

                # 5. Create Recipe Pydantic Object (Including new fields)
                logger.info("Creating final Recipe object...")
                try:
                    current_time_utc = datetime.now(timezone.utc)
                    new_recipe = Recipe(
                        title=title.strip(),
                        instructions=instructions.strip(),
                        ingredients=ingredient_items_list,
                        portata_category=confirmed_category,
                        num_people=num_people_val, # Add new field
                        difficulty=difficulty_val, # Add new field
                        season=season_val,         # Add new field
                        prep_time_minutes=prep_time_val,
                        cook_time_minutes=cook_time_val,
                        source_type="Manuale",
                        created_at=current_time_utc, # Set creation time
                        updated_at=current_time_utc  # Set update time initially
                    )
                    logger.debug(f"Recipe object details: {new_recipe.model_dump(exclude={'ingredients'})}")

                    # 6. Save Recipe to Cosmos DB
                    logger.info("Attempting to save recipe to database...")
                    with st.spinner("Saving recipe..."):
                        if not recipe_container:
                             st.error("Recipe container client is not available. Cannot save.")
                             raise ValueError("Recipe container client is missing.")
                        # Ensure updated_at is set correctly for updates if editing later
                        # For new recipes, Pydantic default is fine, but explicit set is clear
                        new_recipe.updated_at = datetime.now(timezone.utc)
                        saved_recipe = save_recipe(recipe_container, new_recipe)

                    if saved_recipe:
                        st.success(f"Recipe '{saved_recipe.title}' saved successfully!")
                        logger.info(f"Recipe {saved_recipe.id} saved to DB.")
                        # Clear the editor state after successful save
                        st.session_state['manual_ingredients_df'] = pd.DataFrame(
                            [], columns=["Quantity", "Unit", "Ingredient Name", "Notes"]
                        )
                        st.session_state['confirmed_ingredient_map'] = {}
                        st.rerun() # Rerun to clear form and show success
                    else:
                        st.error("Failed to save the recipe to the database. Please check logs.")
                        logger.error("Failed to save recipe object to Cosmos DB.")

                except Exception as model_error:
                     st.error(f"Error creating recipe data structure: {model_error}")
                     logger.error(f"Pydantic validation or object creation error: {model_error}", exc_info=True)


        except Exception as e:
            st.error(f"An unexpected error occurred during processing: {e}")
            logger.error(f"Error during recipe processing/saving: {e}", exc_info=True)

