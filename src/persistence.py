# -*- coding: utf-8 -*-
"""
Module for data persistence logic on Azure Cosmos DB.
Contains CRUD functions for Recipes, Ingredient Entities, and Pantry.
REMOVED ingredient similarity check logic during insertion.
"""

import logging
from typing import List, Optional, Dict, Any
from azure.cosmos.exceptions import CosmosResourceNotFoundError, CosmosHttpResponseError
from azure.cosmos.container import ContainerProxy
import re

# Import Pydantic models
try:
    from .models import Recipe, IngredientEntity, Pantry
except ImportError:
    from models import Recipe, IngredientEntity, Pantry

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Helper Functions ---
def _normalize_name_for_search(name: str) -> str:
    """Normalizes a name for searching/comparison (lowercase, single spaces)."""
    if not name: return ""
    normalized = " ".join(name.lower().split())
    return normalized

# --- Functions for Container 'Recipes' ---

def save_recipe(recipe_container: ContainerProxy, recipe: Recipe) -> Optional[Recipe]:
    """Saves or updates a recipe in the Recipes container."""
    try:
        recipe_dict = recipe.model_dump(mode='json', exclude_none=True)
        logger.info(f"Attempting upsert for recipe id: {recipe.id}")
        created_item = recipe_container.upsert_item(body=recipe_dict)
        logger.info(f"Recipe '{created_item.get('title', recipe.id)}' saved/updated successfully.")
        return Recipe.model_validate(created_item)
    except CosmosHttpResponseError as e:
        logger.error(f"Cosmos DB error saving recipe {recipe.id}: {e.message}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error saving recipe {recipe.id}: {e}", exc_info=True)
        return None

def get_recipe_by_id(recipe_container: ContainerProxy, recipe_id: str) -> Optional[Recipe]:
    """Retrieves a specific recipe by its ID (which is also the Partition Key)."""
    try:
        logger.info(f"Retrieving recipe with id: {recipe_id}")
        item = recipe_container.read_item(item=recipe_id, partition_key=recipe_id)
        return Recipe.model_validate(item)
    except CosmosResourceNotFoundError:
        logger.warning(f"Recipe with id {recipe_id} not found.")
        return None
    except CosmosHttpResponseError as e:
        logger.error(f"Cosmos DB error retrieving recipe {recipe_id}: {e.message}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error retrieving recipe {recipe_id}: {e}", exc_info=True)
        return None

def list_all_recipes(recipe_container: ContainerProxy, max_items: int = 100) -> List[Recipe]:
    """Retrieves a list of recipes (limited). Consider pagination for large datasets."""
    recipes = []
    try:
        logger.info(f"Retrieving up to {max_items} recipes...")
        query = f"SELECT * FROM c OFFSET 0 LIMIT @max_items"
        items = list(recipe_container.query_items(
            query=query,
            parameters=[{"name": "@max_items", "value": max_items}],
            enable_cross_partition_query=True
        ))
        for item in items:
            try: recipes.append(Recipe.model_validate(item))
            except Exception as validation_error: logger.warning(f"Pydantic validation error for recipe item {item.get('id')}: {validation_error}")
        logger.info(f"Retrieved {len(recipes)} recipes.")
    except CosmosHttpResponseError as e: logger.error(f"Cosmos DB error listing recipes: {e.message}")
    except Exception as e: logger.error(f"Unexpected error listing recipes: {e}", exc_info=True)
    return recipes

def delete_recipe(recipe_container: ContainerProxy, recipe_id: str) -> bool:
    """Deletes a specific recipe by its ID (which is also the Partition Key)."""
    try:
        logger.info(f"Attempting to delete recipe with id: {recipe_id}")
        recipe_container.delete_item(item=recipe_id, partition_key=recipe_id)
        logger.info(f"Recipe {recipe_id} deleted successfully.")
        return True
    except CosmosResourceNotFoundError: logger.warning(f"Cannot delete: Recipe {recipe_id} not found."); return False
    except CosmosHttpResponseError as e: logger.error(f"Cosmos DB error deleting recipe {recipe_id}: {e.message}"); return False
    except Exception as e: logger.error(f"Unexpected error deleting recipe {recipe_id}: {e}", exc_info=True); return False

# --- Functions for Container 'IngredientsMasterList' ---

def get_ingredient_entity(ingredients_container: ContainerProxy, ingredient_id: str) -> Optional[IngredientEntity]:
    """Retrieves a specific IngredientEntity by its ID (which is also Partition Key)."""
    try:
        item = ingredients_container.read_item(item=ingredient_id, partition_key=ingredient_id)
        return IngredientEntity.model_validate(item)
    except CosmosResourceNotFoundError: return None
    except CosmosHttpResponseError as e: logger.error(f"Cosmos DB error retrieving IngredientEntity {ingredient_id}: {e.message}"); return None
    except Exception as e: logger.error(f"Unexpected error retrieving IngredientEntity {ingredient_id}: {e}", exc_info=True); return None

# --- REMOVED find_similar_ingredient_display_names function ---

def upsert_ingredient_entity(ingredients_container: ContainerProxy, ingredient: IngredientEntity) -> Optional[IngredientEntity]:
    """Saves or updates an IngredientEntity."""
    try:
        # Ensure normalized name is set before saving
        if not ingredient.normalized_search_name and ingredient.displayName:
             ingredient.normalized_search_name = _normalize_name_for_search(ingredient.displayName)

        ingredient_dict = ingredient.model_dump(mode='json', exclude_none=True)
        logger.debug(f"Attempting upsert for IngredientEntity id: {ingredient.id}")
        created_item = ingredients_container.upsert_item(body=ingredient_dict)
        logger.info(f"IngredientEntity '{created_item.get('displayName')}' saved/updated.")
        return IngredientEntity.model_validate(created_item)
    except CosmosHttpResponseError as e:
        logger.error(f"Cosmos DB error upserting IngredientEntity {ingredient.id}: {e.message}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error upserting IngredientEntity {ingredient.id}: {e}", exc_info=True)
        return None

def delete_ingredient_entity(ingredients_container: ContainerProxy, ingredient_id: str) -> bool:
    """Deletes a specific IngredientEntity by its ID (which is also Partition Key)."""
    try:
        logger.info(f"Attempting to delete IngredientEntity with id: {ingredient_id}")
        ingredients_container.delete_item(item=ingredient_id, partition_key=ingredient_id)
        logger.info(f"IngredientEntity {ingredient_id} deleted successfully.")
        return True
    except CosmosResourceNotFoundError:
        logger.warning(f"Cannot delete: IngredientEntity {ingredient_id} not found.")
        return False
    except CosmosHttpResponseError as e:
        logger.error(f"Cosmos DB error deleting IngredientEntity {ingredient_id}: {e.message}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error deleting IngredientEntity {ingredient_id}: {e}", exc_info=True)
        return False

# --- Functions for Container 'Pantry' ---

def get_pantry(pantry_container: ContainerProxy, pantry_id: str = "pantry_default") -> Pantry:
    """Retrieves the pantry state. Creates an empty one if not found."""
    try:
        logger.info(f"Retrieving pantry with id: {pantry_id}")
        item = pantry_container.read_item(item=pantry_id, partition_key=pantry_id)
        return Pantry.model_validate(item)
    except CosmosResourceNotFoundError:
        logger.warning(f"Pantry with id {pantry_id} not found. Returning empty pantry.")
        return Pantry(id=pantry_id, ingredient_ids=[]) # Return default empty
    except CosmosHttpResponseError as e:
        logger.error(f"Cosmos DB error retrieving pantry {pantry_id}: {e.message}")
        return Pantry(id=pantry_id, ingredient_ids=[]) # Return default empty on error
    except Exception as e:
        logger.error(f"Unexpected error retrieving pantry {pantry_id}: {e}", exc_info=True)
        return Pantry(id=pantry_id, ingredient_ids=[]) # Return default empty on error

def update_pantry(pantry_container: ContainerProxy, pantry: Pantry) -> Optional[Pantry]:
    """Updates the entire pantry state."""
    try:
        pantry_dict = pantry.model_dump(mode='json', exclude_none=True)
        logger.info(f"Attempting update for pantry id: {pantry.id}")
        updated_item = pantry_container.upsert_item(body=pantry_dict)
        logger.info(f"Pantry {pantry.id} updated successfully.")
        return Pantry.model_validate(updated_item)
    except CosmosHttpResponseError as e:
        logger.error(f"Cosmos DB error updating pantry {pantry.id}: {e.message}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error updating pantry {pantry.id}: {e}", exc_info=True)
        return None

# --- Additional Query Functions ---

def get_recipes_by_category(recipe_container: ContainerProxy, category: str, max_items: int = 50) -> List[Recipe]:
    """ Retrieves recipes by category using a filter query. """
    recipes = []
    if not category: return recipes
    try:
        logger.info(f"Retrieving recipes for category '{category}' (max {max_items})...")
        query = "SELECT * FROM c WHERE c.category = @category OFFSET 0 LIMIT @max_items"
        parameters = [{"name": "@category", "value": category}, {"name": "@max_items", "value": max_items}]
        items = list(recipe_container.query_items(query=query, parameters=parameters, enable_cross_partition_query=True))
        for item in items:
            try: recipes.append(Recipe.model_validate(item))
            except Exception as validation_error: logger.warning(f"Pydantic validation error for recipe item {item.get('id')}: {validation_error}")
        logger.info(f"Retrieved {len(recipes)} recipes for category '{category}'.")
    except CosmosHttpResponseError as e: logger.error(f"Cosmos DB error retrieving recipes by category '{category}': {e.message}")
    except Exception as e: logger.error(f"Unexpected error retrieving recipes by category '{category}': {e}", exc_info=True)
    return recipes

def get_recipes_containing_ingredient(recipe_container: ContainerProxy, ingredient_id: str, max_items: int = 50) -> List[Recipe]:
    """ Retrieves recipes containing a specific ingredient ID using JOIN. """
    recipes = []
    if not ingredient_id: return recipes
    try:
        logger.info(f"Retrieving recipes containing ingredient_id '{ingredient_id}' (max {max_items})...")
        # Using JOIN is generally more flexible for querying arrays of objects
        query = """
        SELECT VALUE r
        FROM Recipes r
        JOIN i IN r.ingredients
        WHERE i.ingredient_id = @ingredient_id
        OFFSET 0 LIMIT @max_items
        """
        parameters = [{"name": "@ingredient_id", "value": ingredient_id}, {"name": "@max_items", "value": max_items}]
        items = list(recipe_container.query_items(query=query, parameters=parameters, enable_cross_partition_query=True))
        for item in items:
            try: recipes.append(Recipe.model_validate(item))
            except Exception as validation_error: logger.warning(f"Pydantic validation error for recipe item {item.get('id')}: {validation_error}")
        logger.info(f"Retrieved {len(recipes)} recipes containing '{ingredient_id}'.")
    except CosmosHttpResponseError as e: logger.error(f"Cosmos DB error retrieving recipes by ingredient '{ingredient_id}': {e.message}")
    except Exception as e: logger.error(f"Unexpected error retrieving recipes by ingredient '{ingredient_id}': {e}", exc_info=True)
    return recipes

