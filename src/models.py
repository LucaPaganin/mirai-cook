# -*- coding: utf-8 -*-
"""
Definizione dei modelli dati Pydantic V2 per l'applicazione Mirai Cook.
Queste classi definiscono la struttura, i tipi e la validazione
per le entità principali gestite dall'applicazione (Ricette, Ingredienti, etc.).
Versione finale senza codice commentato di esempio.
Funzione sanitize_for_id aggiornata per usare unidecode.
Aggiunti campi difficulty, num_people, season a Recipe.
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
        # Genera un UUID se il nome è vuoto per evitare ID vuoti
        logger.warning("Attempting to sanitize an empty name, generating UUID.")
        return f"ingredient_{uuid.uuid4()}"

    # 1. Traslittera caratteri Unicode in ASCII (es. à -> a, ç -> c)
    try:
        s = unidecode(name)
    except Exception as e:
        logger.error(f"Error applying unidecode to name '{name}': {e}. Proceeding without unidecode.")
        s = name # Fallback al nome originale in caso di errore di unidecode

    # 2. Converti in minuscolo
    s = s.lower()

    # 3. Sostituisci spazi e caratteri non alfanumerici (esclusi underscore) con underscore
    s = re.sub(r'\s+', '_', s)       # Sostituisce spazi (anche multipli) con _
    s = re.sub(r'[^\w_]+', '', s)    # Rimuove tutto ciò che non è parola (a-zA-Z0-9_) o underscore

    # 4. Rimuovi underscore multipli o iniziali/finali
    s = re.sub(r'_+', '_', s).strip('_')

    # 5. Assicura che non sia vuoto dopo la sanitizzazione
    if not s:
        logger.warning(f"Name '{name}' resulted empty after sanitization with unidecode, generating UUID.")
        return f"ingredient_{uuid.uuid4()}"

    logger.debug(f"Name '{name}' sanitized to ID: '{s}'")
    return s

# --- Funzione Helper per Normalizzazione Nome ---
# (Questa rimane invariata, usata per la ricerca/similarità, non per l'ID)
def _normalize_name_for_search(name: str) -> str:
    """Normalizes a name for searching/comparison (lowercase, single spaces)."""
    if not name:
        return ""
    normalized = " ".join(name.lower().split())
    return normalized

# --- Modelli Principali ---

class IngredientEntity(BaseModel):
    """
    Represents a canonical ingredient in the Master List.
    The ID is the sanitized name and serves as the primary/partition key.
    Uses Pydantic V2.
    """
    id: str = Field(..., description="Unique and immutable ID (sanitized name), Partition Key.")
    displayName: str = Field(..., description="User-facing display name, editable.")
    usage_count: int = Field(default=1, description="Count of recipes using this ingredient.")
    calories_per_100g: Optional[float] = Field(default=None, description="Cached calories per 100g (or standard unit).", ge=0)
    calorie_data_source: Optional[str] = Field(default=None, description="Source of the calorie data (e.g., OpenFoodFacts, USDA, Manual).")
    calorie_last_updated: Optional[datetime] = Field(default=None, description="Timestamp of the last calorie data update (UTC).")
    normalized_search_name: Optional[str] = Field(default=None, description="Normalized version of displayName for internal searches.")

    @model_validator(mode='before')
    @classmethod
    def set_id_and_normalized_name(cls, data: Any) -> Any:
        """
        Validator executed before standard validation to:
        1. Generate 'id' from 'displayName' if 'id' is not provided.
        2. Generate 'normalized_search_name' from 'displayName' if not provided.
        """
        if isinstance(data, dict):
            processed_data = data.copy()
            display_name = processed_data.get('displayName')

            if processed_data.get('id') is None and display_name:
                processed_data['id'] = sanitize_for_id(display_name)
                logger.debug(f"Generated id '{processed_data['id']}' from displayName '{display_name}'")

            if processed_data.get('normalized_search_name') is None and display_name:
                processed_data['normalized_search_name'] = _normalize_name_for_search(display_name)
                logger.debug(f"Generated normalized_search_name '{processed_data['normalized_search_name']}' from displayName '{display_name}'")

            return processed_data
        return data


class IngredientItem(BaseModel):
    """
    Represents an ingredient line item within a specific Recipe.
    Contains quantity, unit, and the reference to the IngredientEntity via ID.
    Uses Pydantic V2.
    """
    ingredient_id: str = Field(..., description="ID of the corresponding IngredientEntity.")
    quantity: Optional[float] = Field(default=None, description="Numeric quantity (optional for 'q.b.', etc.).", ge=0)
    unit: Optional[str] = Field(default=None, description="Unit of measure (e.g., g, ml, tbsp, piece).")
    notes: Optional[str] = Field(default=None, description="Additional notes (e.g., finely chopped).")


class Recipe(BaseModel):
    """
    Represents a complete recipe in the Cookbook.
    The ID is the primary key and Partition Key for the Recipes container.
    Uses Pydantic V2. Includes difficulty, num_people, season.
    """
    # Core fields
    id: str = Field(default_factory=lambda: f"recipe_{uuid.uuid4()}", description="Unique recipe ID, Partition Key.")
    title: str = Field(..., min_length=1, description="Title of the recipe.")
    instructions: str = Field(..., min_length=1, description="Instructions text.")
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), description="Creation timestamp (UTC).")
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), description="Last modification timestamp (UTC).")

    # Structured data
    ingredients: List[IngredientItem] = Field(default=[], description="Structured list of ingredients.")
    portata_category: Optional[str] = Field(default=None, description="Course category confirmed by the user.")

    # --- NEW FIELDS ---
    num_people: Optional[int] = Field(default=None, ge=1, description="Number of people the recipe serves.")
    difficulty: Optional[str] = Field(default=None, description="Recipe difficulty level (e.g., Easy, Medium, Hard).")
    season: Optional[str] = Field(default=None, description="Best season for the recipe (e.g., Spring, Summer, All).")
    # --- END NEW FIELDS ---

    # AI and Metadata
    ai_suggested_categories: List[str] = Field(default=[], description="AI-suggested categories (for reference).")
    source_url: Optional[str] = Field(default=None, description="Origin URL if imported.")
    source_type: Optional[str] = Field(default=None, description="Origin: Manual, Digitized, Imported, AI Generated.")
    image_url: Optional[str] = Field(default=None, description="URL of the finished dish photo (in Blob Storage).")
    image_tags: List[str] = Field(default=[], description="Tags extracted from the image (AI Vision).")
    image_description: Optional[str] = Field(default=None, description="Caption generated for the image (AI Vision).")
    prep_time_minutes: Optional[int] = Field(default=None, ge=0, description="Estimated preparation time in minutes.")
    cook_time_minutes: Optional[int] = Field(default=None, ge=0, description="Estimated cooking time in minutes.")
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

