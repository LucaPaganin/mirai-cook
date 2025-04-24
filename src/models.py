# -*- coding: utf-8 -*-
"""
Definizione dei modelli dati Pydantic V2 per l'applicazione Mirai Cook.
Queste classi definiscono la struttura, i tipi e la validazione
per le entità principali gestite dall'applicazione (Ricette, Ingredienti, etc.).
Versione finale senza codice commentato di esempio.
Funzione sanitize_for_id aggiornata per usare unidecode.
Aggiunti campi difficulty, num_people, season a Recipe.
Consolidato prep_time e cook_time in total_time_minutes.
Rinominato portata_category in category.
Aggiunto campo opzionale 'drink'.
"""

from pydantic import BaseModel, Field, model_validator
from typing import List, Optional, Any
from datetime import datetime, timezone # Assicurati di usare timezone aware datetime
import uuid
import re # Per la sanitizzazione dell'ID ingrediente
import logging # Aggiunto per eventuali log futuri se necessari
from unidecode import unidecode # Importa unidecode

# Configurazione base del logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Funzione Helper per Sanitizzazione ID (Aggiornata con unidecode) ---
def sanitize_for_id(name: str) -> str:
    """
    Crea un ID leggibile e utilizzabile come chiave da un nome,
    usando unidecode per una migliore gestione dei caratteri internazionali/accentati.
    """
    if not name:
        logger.warning("Attempting to sanitize an empty name, generating UUID.")
        return f"ingredient_{uuid.uuid4()}"
    try:
        s = unidecode(name)
    except Exception as e:
        logger.error(f"Error applying unidecode to name '{name}': {e}. Proceeding without unidecode.")
        s = name
    s = s.lower()
    s = re.sub(r'\s+', '_', s)
    s = re.sub(r'[^\w_]+', '', s)
    s = re.sub(r'_+', '_', s).strip('_')
    if not s:
        logger.warning(f"Name '{name}' resulted empty after sanitization with unidecode, generating UUID.")
        return f"ingredient_{uuid.uuid4()}"
    logger.debug(f"Name '{name}' sanitized to ID: '{s}'")
    return s

# --- Funzione Helper per Normalizzazione Nome ---
def _normalize_name_for_search(name: str) -> str:
    """Normalizes a name for searching/comparison (lowercase, single spaces)."""
    if not name: return ""
    normalized = " ".join(name.lower().split())
    return normalized

# --- Modelli Principali ---

class IngredientEntity(BaseModel):
    """
    Represents a canonical ingredient in the Master List.
    Uses Pydantic V2.
    """
    id: str = Field(..., description="Unique and immutable ID (sanitized name), Partition Key.")
    displayName: str = Field(..., description="User-facing display name, editable.")
    usage_count: int = Field(default=1, description="Count of recipes using this ingredient.")
    calories_per_100g: Optional[float] = Field(default=None, description="Cached calories per 100g (or standard unit).", ge=0)
    calorie_data_source: Optional[str] = Field(default=None, description="Source of the calorie data.")
    calorie_last_updated: Optional[datetime] = Field(default=None, description="Timestamp of the last calorie data update (UTC).")
    normalized_search_name: Optional[str] = Field(default=None, description="Normalized version of displayName for internal searches.")

    @model_validator(mode='before')
    @classmethod
    def set_id_and_normalized_name(cls, data: Any) -> Any:
        """Generates 'id' and 'normalized_search_name' if not provided."""
        if isinstance(data, dict):
            processed_data = data.copy()
            display_name = processed_data.get('displayName')
            if processed_data.get('id') is None and display_name:
                processed_data['id'] = sanitize_for_id(display_name)
            if processed_data.get('normalized_search_name') is None and display_name:
                processed_data['normalized_search_name'] = _normalize_name_for_search(display_name)
            return processed_data
        return data


class IngredientItem(BaseModel):
    """
    Represents an ingredient line item within a specific Recipe.
    Uses Pydantic V2.
    """
    ingredient_id: str = Field(..., description="ID of the corresponding IngredientEntity.")
    quantity: Optional[float] = Field(default=None, description="Numeric quantity (optional for 'q.b.', etc.).", ge=0)
    unit: Optional[str] = Field(default=None, description="Unit of measure (e.g., g, ml, tbsp, piece).") # Optional unit
    notes: Optional[str] = Field(default=None, description="Additional notes (e.g., finely chopped).")


class Recipe(BaseModel):
    """
    Represents a complete recipe in the Cookbook.
    Uses Pydantic V2. Includes optional drink pairing.
    """
    id: str = Field(default_factory=lambda: f"recipe_{uuid.uuid4()}", description="Unique recipe ID, Partition Key.")
    title: str = Field(..., min_length=1, description="Title of the recipe.")
    instructions: str = Field(..., min_length=1, description="Instructions text.")
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), description="Creation timestamp (UTC).")
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), description="Last modification timestamp (UTC).")
    ingredients: List[IngredientItem] = Field(default=[], description="Structured list of ingredients.")
    category: Optional[str] = Field(default=None, description="Recipe category (e.g., Primo, Dolce), user-confirmed or entered.")
    num_people: Optional[int] = Field(default=None, ge=1, description="Number of people the recipe serves.")
    difficulty: Optional[str] = Field(default=None, description="Recipe difficulty level (e.g., Easy, Medium, Hard).")
    season: Optional[str] = Field(default=None, description="Best season for the recipe (e.g., Spring, Summer, All).")
    total_time_minutes: Optional[int] = Field(default=None, ge=0, description="Estimated total time (prep + cook) in minutes.")
    # --- NEW FIELD ---
    drink: Optional[str] = Field(default=None, description="Suggested drink pairing for the recipe.")
    # --- END NEW FIELD ---
    ai_suggested_categories: List[str] = Field(default=[], description="AI-suggested categories (for reference).")
    source_url: Optional[str] = Field(default=None, description="Origin URL if imported.")
    source_type: Optional[str] = Field(default=None, description="Origin: Manual, Digitized, Imported, AI Generated.")
    image_url: Optional[str] = Field(default=None, description="URL of the finished dish photo (in Blob Storage).")
    image_tags: List[str] = Field(default=[], description="Tags extracted from the image (AI Vision).")
    image_description: Optional[str] = Field(default=None, description="Caption generated for the image (AI Vision).")
    total_calories_estimated: Optional[int] = Field(default=None, ge=0, description="Estimated total calories calculated.")


class Pantry(BaseModel):
    """
    Represents the user's pantry (single user in this version).
    Contains the list of available ingredient IDs.
    Uses Pydantic V2.
    """
    id: str = Field(default="pantry_default", description="Fixed ID for the single user pantry, Partition Key.")
    ingredient_ids: List[str] = Field(default=[], description="List of ingredient_ids present in the pantry.")
    last_updated: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), description="Last update timestamp (UTC).")

