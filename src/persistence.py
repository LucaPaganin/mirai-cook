# -*- coding: utf-8 -*-
"""
Modulo per la logica di persistenza dei dati su Azure Cosmos DB.
Contiene funzioni per creare, leggere, aggiornare ed eliminare (CRUD)
le entità principali dell'applicazione Mirai Cook (Ricette, Ingredienti, Dispensa).
"""

import logging
from typing import List, Optional, Dict, Any
from azure.cosmos.exceptions import CosmosResourceNotFoundError, CosmosHttpResponseError
from azure.cosmos.container import ContainerProxy
from Levenshtein import distance as levenshtein_distance # Per la similarità
import re

# Importa i modelli Pydantic definiti in models.py
try:
    from .models import Recipe, IngredientEntity, Pantry, IngredientItem, sanitize_for_id
except ImportError:
    # Fallback per esecuzione script standalone o se la struttura è diversa
    from src.models import Recipe, IngredientEntity, Pantry, IngredientItem, sanitize_for_id

# Configurazione del logging (buona pratica)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Funzioni Helper ---
def _normalize_name_for_search(name: str) -> str:
    """Normalizza un nome per la ricerca/confronto (minuscolo, spazi singoli)."""
    if not name:
        return ""
    return " ".join(name.lower().split())

# --- Funzioni per interagire con il Container 'Recipes' ---

def save_recipe(recipe_container: ContainerProxy, recipe: Recipe) -> Optional[Recipe]:
    """
    Salva (o aggiorna se l'ID esiste già) una ricetta nel container Recipes.
    Assume che gli ingredient_id all'interno della ricetta siano già stati validati
    e che l'oggetto Recipe sia valido secondo il modello Pydantic.
    Gestisce l'aggiornamento del timestamp 'updated_at'.
    Restituisce l'oggetto Recipe salvato o None in caso di errore.
    """
    try:
        # Aggiorna il timestamp 'updated_at' (Pydantic lo fa con default_factory,
        # ma potremmo volerlo forzare qui se è un update)
        # from datetime import datetime
        # recipe.updated_at = datetime.utcnow() # Se non si usa default_factory

        recipe_dict = recipe.model_dump(mode='json', exclude_none=True) # Esclude i campi None per pulizia DB
        logger.info(f"Tentativo di upsert ricetta con id: {recipe.id}")
        created_item = recipe_container.upsert_item(body=recipe_dict)
        logger.info(f"Ricetta '{created_item.get('title', recipe.id)}' salvata/aggiornata con successo.")
        # Riconverti il risultato in oggetto Pydantic validato
        return Recipe.model_validate(created_item)
    except CosmosHttpResponseError as e:
        logger.error(f"Errore Cosmos DB durante il salvataggio della ricetta {recipe.id}: {e.message}")
        return None
    except Exception as e:
        logger.error(f"Errore imprevisto durante il salvataggio della ricetta {recipe.id}: {e}", exc_info=True)
        return None

def get_recipe_by_id(recipe_container: ContainerProxy, recipe_id: str) -> Optional[Recipe]:
    """
    Recupera una ricetta specifica tramite il suo ID (che è anche Partition Key).
    Restituisce l'oggetto Recipe o None se non trovata o in caso di errore.
    """
    try:
        logger.info(f"Recupero ricetta con id: {recipe_id}")
        # Assumendo che la Partition Key sia l'ID stesso
        item = recipe_container.read_item(item=recipe_id, partition_key=recipe_id)
        return Recipe.model_validate(item)
    except CosmosResourceNotFoundError:
        logger.warning(f"Ricetta con id {recipe_id} non trovata.")
        return None
    except CosmosHttpResponseError as e:
        logger.error(f"Errore Cosmos DB durante il recupero della ricetta {recipe_id}: {e.message}")
        return None
    except Exception as e:
        logger.error(f"Errore imprevisto durante il recupero della ricetta {recipe_id}: {e}", exc_info=True)
        return None

def list_all_recipes(recipe_container: ContainerProxy, max_items: int = 100) -> List[Recipe]:
    """
    Recupera una lista di ricette (con un limite massimo).
    ATTENZIONE: Query cross-partizione se la PK non è fissa, può essere costosa.
    Considerare paginazione o query più specifiche per produzione.
    """
    recipes = []
    try:
        logger.info(f"Recupero delle prime {max_items} ricette...")
        query = f"SELECT * FROM c OFFSET 0 LIMIT @max_items"
        items = list(recipe_container.query_items(
            query=query,
            parameters=[{"name": "@max_items", "value": max_items}],
            enable_cross_partition_query=True # Necessario se PK != valore fisso
        ))
        for item in items:
            try:
                recipes.append(Recipe.model_validate(item))
            except Exception as validation_error:
                 logger.warning(f"Errore validazione Pydantic per item ricetta {item.get('id')}: {validation_error}")
        logger.info(f"Recuperate {len(recipes)} ricette.")
    except CosmosHttpResponseError as e:
        logger.error(f"Errore Cosmos DB durante il recupero delle ricette: {e.message}")
    except Exception as e:
        logger.error(f"Errore imprevisto durante il recupero delle ricette: {e}", exc_info=True)
    return recipes

def delete_recipe(recipe_container: ContainerProxy, recipe_id: str) -> bool:
    """
    Elimina una ricetta specifica tramite il suo ID (che è anche Partition Key).
    Restituisce True se l'eliminazione ha successo, False altrimenti.
    """
    try:
        logger.info(f"Tentativo di eliminazione ricetta con id: {recipe_id}")
        recipe_container.delete_item(item=recipe_id, partition_key=recipe_id)
        logger.info(f"Ricetta {recipe_id} eliminata con successo.")
        return True
    except CosmosResourceNotFoundError:
        logger.warning(f"Impossibile eliminare: Ricetta {recipe_id} non trovata.")
        return False
    except CosmosHttpResponseError as e:
        logger.error(f"Errore Cosmos DB durante l'eliminazione della ricetta {recipe_id}: {e.message}")
        return False
    except Exception as e:
        logger.error(f"Errore imprevisto durante l'eliminazione della ricetta {recipe_id}: {e}", exc_info=True)
        return False

# --- Funzioni per interagire con il Container 'IngredientsMasterList' ---

def get_ingredient_entity(ingredients_container: ContainerProxy, ingredient_id: str) -> Optional[IngredientEntity]:
    """
    Recupera un IngredientEntity specifico tramite il suo ID (che è anche Partition Key).
    """
    try:
        # logger.debug(f"Recupero IngredientEntity con id: {ingredient_id}")
        item = ingredients_container.read_item(item=ingredient_id, partition_key=ingredient_id)
        return IngredientEntity.model_validate(item)
    except CosmosResourceNotFoundError:
        # logger.debug(f"IngredientEntity con id {ingredient_id} non trovato.")
        return None
    except CosmosHttpResponseError as e:
        logger.error(f"Errore Cosmos DB durante recupero IngredientEntity {ingredient_id}: {e.message}")
        return None
    except Exception as e:
        logger.error(f"Errore imprevisto recupero IngredientEntity {ingredient_id}: {e}", exc_info=True)
        return None

def find_similar_ingredient_display_names(
    ingredients_container: ContainerProxy,
    display_name_to_check: str,
    threshold: int = 2, # Soglia di distanza Levenshtein (più bassa = più simile)
    limit: int = 3     # Massimo numero di risultati simili da restituire
) -> List[IngredientEntity]:
    """
    Trova IngredientEntity con displayName simile a quello fornito, usando Levenshtein.
    Ottimizzazione: Cerca solo tra ingredienti con iniziale simile o usa campo normalizzato.
    """
    normalized_check = _normalize_name_for_search(display_name_to_check)
    if not normalized_check:
        return []

    similar_ingredients = []
    checked_ids = set()

    try:
        # Strategia di Query Ottimizzata: Cerca usando il campo normalizzato (se esiste e indicizzato)
        # o almeno filtrando per la prima lettera per ridurre i candidati.
        # Assumiamo esista il campo 'normalized_search_name' nel modello e sia indicizzato.
        # Se non esiste, questa query fallirà o sarà inefficiente.
        # Potremmo dover recuperare tutti gli item se il DB è piccolo.

        # Query per candidati con nome normalizzato simile (es. stessa iniziale)
        # Nota: Cosmos DB non supporta Levenshtein nativamente. Il calcolo va fatto in Python.
        # Questa query recupera candidati, poi filtriamo.
        # Potrebbe essere necessario adattare la query in base all'indicizzazione effettiva.
        first_letter = normalized_check[0]
        query = "SELECT * FROM c WHERE STARTSWITH(c.normalized_search_name, @prefix)"
        parameters = [{"name": "@prefix", "value": first_letter}]

        logger.info(f"Ricerca candidati simili per '{display_name_to_check}' (normalizzato: '{normalized_check}') con prefisso '{first_letter}'...")
        items = list(ingredients_container.query_items(
            query=query,
            parameters=parameters,
            enable_cross_partition_query=True # Probabilmente non necessario se PK è /id, ma sicuro
        ))
        logger.info(f"Trovati {len(items)} candidati iniziali.")

        # Calcola distanza e filtra
        for item in items:
            ingredient_id = item.get("id")
            if not ingredient_id or ingredient_id in checked_ids:
                continue

            existing_normalized = item.get("normalized_search_name")
            if not existing_normalized:
                # Fallback se manca il campo normalizzato: usa displayName
                existing_normalized = _normalize_name_for_search(item.get("displayName", ""))

            if not existing_normalized:
                continue

            # Calcola distanza di Levenshtein
            dist = levenshtein_distance(normalized_check, existing_normalized)

            if dist <= threshold:
                try:
                    entity = IngredientEntity.model_validate(item)
                    similar_ingredients.append({"entity": entity, "distance": dist})
                    checked_ids.add(ingredient_id)
                except Exception as validation_error:
                     logger.warning(f"Errore validazione Pydantic per item ingrediente {ingredient_id}: {validation_error}")

        # Ordina per distanza (i più simili prima) e prendi il limite
        similar_ingredients.sort(key=lambda x: x["distance"])
        result_entities = [item["entity"] for item in similar_ingredients[:limit]]
        logger.info(f"Trovati {len(result_entities)} ingredienti simili entro soglia {threshold} per '{display_name_to_check}'.")
        return result_entities

    except CosmosHttpResponseError as e:
        logger.error(f"Errore Cosmos DB durante ricerca ingredienti simili: {e.message}")
    except Exception as e:
        logger.error(f"Errore imprevisto ricerca ingredienti simili: {e}", exc_info=True)
    return []


def upsert_ingredient_entity(ingredients_container: ContainerProxy, ingredient: IngredientEntity) -> Optional[IngredientEntity]:
    """
    Salva (o aggiorna) un IngredientEntity.
    Assume che l'ID sia la Partition Key. Si assicura che normalized_search_name sia popolato.
    """
    try:
        # Assicura che il nome normalizzato sia presente prima di salvare
        if not ingredient.normalized_search_name and ingredient.displayName:
             ingredient.normalized_search_name = _normalize_name_for_search(ingredient.displayName)

        ingredient_dict = ingredient.model_dump(mode='json', exclude_none=True)
        logger.debug(f"Tentativo di upsert IngredientEntity: {ingredient_dict}")
        created_item = ingredients_container.upsert_item(body=ingredient_dict)
        logger.info(f"IngredientEntity '{created_item.get('displayName')}' salvato/aggiornato.")
        return IngredientEntity.model_validate(created_item)
    except CosmosHttpResponseError as e:
        logger.error(f"Errore Cosmos DB durante upsert IngredientEntity {ingredient.id}: {e.message}")
        return None
    except Exception as e:
        logger.error(f"Errore imprevisto upsert IngredientEntity {ingredient.id}: {e}", exc_info=True)
        return None

def delete_ingredient_entity(ingredients_container: ContainerProxy, ingredient_id: str) -> bool:
    """
    Elimina un IngredientEntity specifico tramite il suo ID (che è anche Partition Key).
    Restituisce True se l'eliminazione ha successo, False altrimenti.
    """
    try:
        logger.info(f"Tentativo di eliminazione IngredientEntity con id: {ingredient_id}")
        ingredients_container.delete_item(item=ingredient_id, partition_key=ingredient_id)
        logger.info(f"IngredientEntity {ingredient_id} eliminato con successo.")
        return True
    except CosmosResourceNotFoundError:
        logger.warning(f"Impossibile eliminare: IngredientEntity {ingredient_id} non trovato.")
        return False
    except CosmosHttpResponseError as e:
        logger.error(f"Errore Cosmos DB durante l'eliminazione di IngredientEntity {ingredient_id}: {e.message}")
        return False
    except Exception as e:
        logger.error(f"Errore imprevisto durante l'eliminazione di IngredientEntity {ingredient_id}: {e}", exc_info=True)
        return False


# --- Funzioni per interagire con il Container 'Pantry' ---

def get_pantry(pantry_container: ContainerProxy, pantry_id: str = "pantry_default") -> Pantry:
    """
    Recupera lo stato della dispensa. Assume un ID fisso per single-user.
    L'ID è anche la Partition Key. Se non esiste, ne crea una vuota.
    """
    try:
        logger.info(f"Recupero dispensa con id: {pantry_id}")
        item = pantry_container.read_item(item=pantry_id, partition_key=pantry_id)
        return Pantry.model_validate(item)
    except CosmosResourceNotFoundError:
        logger.warning(f"Dispensa con id {pantry_id} non trovata. Ne creo una vuota.")
        # Ritorna un oggetto Pantry vuoto se non esiste
        return Pantry(id=pantry_id, ingredient_ids=[])
    except CosmosHttpResponseError as e:
        logger.error(f"Errore Cosmos DB durante recupero dispensa {pantry_id}: {e.message}")
        # Ritorna pantry vuoto in caso di errore grave per non bloccare l'app? O solleva eccezione?
        # Per ora ritorniamo vuoto, ma andrebbe gestito meglio.
        return Pantry(id=pantry_id, ingredient_ids=[])
    except Exception as e:
        logger.error(f"Errore imprevisto recupero dispensa {pantry_id}: {e}", exc_info=True)
        return Pantry(id=pantry_id, ingredient_ids=[])


def update_pantry(pantry_container: ContainerProxy, pantry: Pantry) -> Optional[Pantry]:
    """
    Aggiorna l'intero stato della dispensa.
    """
    try:
        # Assicura che il timestamp last_updated sia aggiornato
        # pantry.last_updated = datetime.utcnow() # Gestito da Pydantic default_factory
        pantry_dict = pantry.model_dump(mode='json', exclude_none=True)
        logger.info(f"Tentativo di update dispensa con id: {pantry.id}")
        updated_item = pantry_container.upsert_item(body=pantry_dict)
        logger.info(f"Dispensa {pantry.id} aggiornata.")
        return Pantry.model_validate(updated_item)
    except CosmosHttpResponseError as e:
        logger.error(f"Errore Cosmos DB durante update dispensa {pantry.id}: {e.message}")
        return None
    except Exception as e:
        logger.error(f"Errore imprevisto update dispensa {pantry.id}: {e}", exc_info=True)
        return None

# --- Funzioni di Query Aggiuntive (Esempi) ---

def get_recipes_by_category(recipe_container: ContainerProxy, category: str, max_items: int = 50) -> List[Recipe]:
    """ Recupera ricette per categoria (richiede query con filtro) """
    recipes = []
    try:
        logger.info(f"Recupero ricette per categoria '{category}' (max {max_items})...")
        # Assumendo che 'portata_category' sia il campo da filtrare
        # Questa query sarà cross-partizione se la PK è /id
        query = "SELECT * FROM c WHERE c.portata_category = @category OFFSET 0 LIMIT @max_items"
        parameters = [
            {"name": "@category", "value": category},
            {"name": "@max_items", "value": max_items}
        ]
        items = list(recipe_container.query_items(
            query=query,
            parameters=parameters,
            enable_cross_partition_query=True # Probabilmente necessario
        ))
        for item in items:
            try:
                recipes.append(Recipe.model_validate(item))
            except Exception as validation_error:
                 logger.warning(f"Errore validazione Pydantic per item ricetta {item.get('id')}: {validation_error}")
        logger.info(f"Recuperate {len(recipes)} ricette per categoria '{category}'.")
    except CosmosHttpResponseError as e:
        logger.error(f"Errore Cosmos DB durante recupero ricette per categoria '{category}': {e.message}")
    except Exception as e:
        logger.error(f"Errore imprevisto recupero ricette per categoria '{category}': {e}", exc_info=True)
    return recipes

def get_recipes_containing_ingredient(recipe_container: ContainerProxy, ingredient_id: str, max_items: int = 50) -> List[Recipe]:
    """
    Recupera ricette che usano un certo ingrediente (tramite ingredient_id).
    Utilizza ARRAY_CONTAINS sulla lista nidificata 'ingredients'.
    """
    recipes = []
    try:
        logger.info(f"Recupero ricette contenenti ingredient_id '{ingredient_id}' (max {max_items})...")
        # Query che cerca l'ID nell'array di oggetti 'ingredients'
        # Nota: ARRAY_CONTAINS cerca un match esatto dell'oggetto, quindi dobbiamo specificare
        # il path al campo 'ingredient_id' all'interno degli oggetti dell'array.
        # La sintassi esatta potrebbe richiedere aggiustamenti o un approccio UDF se complessa.
        # Tentativo con JOIN (più standard per interrogare array di oggetti):
        query = """
        SELECT VALUE r
        FROM r IN Recipes
        JOIN i IN r.ingredients
        WHERE i.ingredient_id = @ingredient_id
        OFFSET 0 LIMIT @max_items
        """
        # Alternativa con ARRAY_CONTAINS (potrebbe richiedere un formato specifico del terzo argomento
        # se si cerca solo una proprietà nell'oggetto array):
        # query = "SELECT * FROM c WHERE ARRAY_CONTAINS(c.ingredients, {'ingredient_id': @ingredient_id}, true) OFFSET 0 LIMIT @max_items"

        parameters = [
            {"name": "@ingredient_id", "value": ingredient_id},
            {"name": "@max_items", "value": max_items}
        ]
        items = list(recipe_container.query_items(
            query=query,
            parameters=parameters,
            enable_cross_partition_query=True # Probabilmente necessario
        ))
        for item in items:
            try:
                recipes.append(Recipe.model_validate(item))
            except Exception as validation_error:
                 logger.warning(f"Errore validazione Pydantic per item ricetta {item.get('id')}: {validation_error}")
        logger.info(f"Recuperate {len(recipes)} ricette contenenti '{ingredient_id}'.")
    except CosmosHttpResponseError as e:
        logger.error(f"Errore Cosmos DB recupero ricette per ingrediente '{ingredient_id}': {e.message}")
    except Exception as e:
        logger.error(f"Errore imprevisto recupero ricette per ingrediente '{ingredient_id}': {e}", exc_info=True)
    return recipes

