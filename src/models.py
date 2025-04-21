# -*- coding: utf-8 -*-
"""
Definizione dei modelli dati Pydantic V2 per l'applicazione Mirai Cook.
Queste classi definiscono la struttura, i tipi e la validazione
per le entità principali gestite dall'applicazione (Ricette, Ingredienti, etc.).
Versione finale senza codice commentato di esempio.
Funzione sanitize_for_id aggiornata per usare unidecode.
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
        logger.warning("Tentativo di sanitizzare un nome vuoto, genero UUID.")
        return f"ingredient_{uuid.uuid4()}"

    # 1. Traslittera caratteri Unicode in ASCII (es. à -> a, ç -> c)
    try:
        s = unidecode(name)
    except Exception as e:
        logger.error(f"Errore durante l'applicazione di unidecode al nome '{name}': {e}. Procedo senza unidecode.")
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
        logger.warning(f"Nome '{name}' risultato vuoto dopo sanitizzazione con unidecode, genero UUID.")
        return f"ingredient_{uuid.uuid4()}"

    logger.debug(f"Nome '{name}' sanitizzato in ID: '{s}'")
    return s

# --- Funzione Helper per Normalizzazione Nome ---
# (Questa rimane invariata, usata per la ricerca/similarità, non per l'ID)
def _normalize_name_for_search(name: str) -> str:
    """Normalizza un nome per la ricerca/confronto (minuscolo, spazi singoli)."""
    if not name:
        return ""
    normalized = " ".join(name.lower().split())
    return normalized

# --- Modelli Principali ---

class IngredientEntity(BaseModel):
    """
    Rappresenta un ingrediente canonico nella Master List.
    L'ID è il nome sanitizzato e funge da chiave primaria/partition key.
    Utilizza Pydantic V2.
    """
    id: str = Field(..., description="ID univoco e immutabile (nome sanitizzato), Partition Key.")
    displayName: str = Field(..., description="Nome visualizzato all'utente, modificabile.")
    usage_count: int = Field(default=1, description="Conteggio di quante ricette usano questo ingrediente.")
    calories_per_100g: Optional[float] = Field(default=None, description="Calorie cachate per 100g (o unità standard).", ge=0)
    calorie_data_source: Optional[str] = Field(default=None, description="Fonte del dato calorico (es. OpenFoodFacts, USDA, Manuale).")
    calorie_last_updated: Optional[datetime] = Field(default=None, description="Timestamp ultimo aggiornamento calorie (UTC).")
    normalized_search_name: Optional[str] = Field(default=None, description="Versione normalizzata del displayName per ricerche interne.")

    @model_validator(mode='before')
    @classmethod
    def set_id_and_normalized_name(cls, data: Any) -> Any:
        """
        Validatore eseguito prima della validazione standard per:
        1. Generare 'id' da 'displayName' se 'id' non è fornito (usa sanitize_for_id aggiornata).
        2. Generare 'normalized_search_name' da 'displayName' se non fornito.
        """
        if isinstance(data, dict):
            processed_data = data.copy()
            display_name = processed_data.get('displayName')

            if processed_data.get('id') is None and display_name:
                processed_data['id'] = sanitize_for_id(display_name) # Usa la nuova funzione

            if processed_data.get('normalized_search_name') is None and display_name:
                processed_data['normalized_search_name'] = _normalize_name_for_search(display_name)

            return processed_data
        return data


class IngredientItem(BaseModel):
    """
    Rappresenta una riga ingrediente all'interno di una specifica Ricetta.
    Contiene quantità, unità e il riferimento all'IngredientEntity tramite ID.
    Utilizza Pydantic V2.
    """
    ingredient_id: str = Field(..., description="ID dell'IngredientEntity corrispondente.")
    quantity: Optional[float] = Field(default=None, description="Quantità numerica (opzionale per 'q.b.', etc.).", ge=0)
    unit: Optional[str] = Field(default=None, description="Unità di misura (es. g, ml, cucchiaio, pezzo).")
    notes: Optional[str] = Field(default=None, description="Note aggiuntive (es. tritata finemente).")


class Recipe(BaseModel):
    """
    Rappresenta una ricetta completa nel Ricettario.
    L'ID è la chiave primaria e la Partition Key per il container Recipes.
    Utilizza Pydantic V2.
    """
    id: str = Field(default_factory=lambda: f"recipe_{uuid.uuid4()}", description="ID univoco della ricetta, Partition Key.")
    title: str = Field(..., min_length=1, description="Titolo della ricetta.")
    instructions: str = Field(..., min_length=1, description="Testo delle istruzioni.")
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), description="Timestamp creazione (UTC).")
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), description="Timestamp ultima modifica (UTC).")
    ingredients: List[IngredientItem] = Field(default=[], description="Lista strutturata degli ingredienti.")
    portata_category: Optional[str] = Field(default=None, description="Categoria di portata confermata dall'utente.")
    ai_suggested_categories: List[str] = Field(default=[], description="Categorie suggerite dall'AI (per riferimento).")
    source_url: Optional[str] = Field(default=None, description="URL di origine se importata.")
    source_type: Optional[str] = Field(default=None, description="Origine: Manuale, Digitalizzata, Importata, Generata AI.")
    image_url: Optional[str] = Field(default=None, description="URL dell'immagine del piatto finito (in Blob Storage).")
    image_tags: List[str] = Field(default=[], description="Tag estratti dall'immagine (AI Vision).")
    image_description: Optional[str] = Field(default=None, description="Didascalia generata per l'immagine (AI Vision).")
    prep_time_minutes: Optional[int] = Field(default=None, ge=0, description="Tempo di preparazione stimato in minuti.")
    cook_time_minutes: Optional[int] = Field(default=None, ge=0, description="Tempo di cottura stimato in minuti.")
    total_calories_estimated: Optional[int] = Field(default=None, ge=0, description="Stima calorie totali calcolate.")


class Pantry(BaseModel):
    """
    Rappresenta la dispensa dell'utente (singolo utente in questa versione).
    Contiene la lista degli ID degli ingredienti disponibili.
    Utilizza Pydantic V2.
    """
    id: str = Field(default="pantry_default", description="ID fisso per la dispensa dell'utente unico, Partition Key.")
    ingredient_ids: List[str] = Field(default=[], description="Lista degli ingredient_id presenti in dispensa.")
    last_updated: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), description="Timestamp ultimo aggiornamento (UTC).")

