# -*- coding: utf-8 -*-
"""
Functions for interacting with Azure OpenAI service (Generative AI).
Includes functions for recipe generation, embeddings, and ingredient parsing.
Ingredient parsing functions output one JSON object per ingredient line.
Includes food group and seasonality classification during parsing (using Italian terms).
"""

import logging
import json # For parsing OpenAI response
from typing import Optional, List, Dict, Any
from openai import AzureOpenAI, OpenAIError # Using the 'openai' package configured for Azure
from azure.core.exceptions import HttpResponseError

logger = logging.getLogger(__name__)

# --- Constants for Parsing Prompts (Italian) ---
FOOD_GROUPS_LIST_IT = [
    "Carne Rossa", "Carne Bianca/Pollame", "Pesce", "Crostacei/Molluschi", "Verdura/Ortaggio", "Frutta",
    "Cereale/Grano", "Latticino/Formaggio", "Legume", "Uova", "Frutta Secca/Seme",
    "Spezia/Erba Aromatica", "Olio/Grasso", "Dolcificante/Dessert", "Bevanda",
    "Condimento/Salsa", "Altro"
]
SEASONS_LIST_IT = ["Primavera", "Estate", "Autunno", "Inverno", "Tutto l'anno", "Non Applicabile"]

# --- OpenAI Service ---

def generate_recipe_from_prompt(
    openai_client: AzureOpenAI,
    prompt: str,
    model_deployment_name: str,
    max_tokens: int = 1500,
    temperature: float = 0.7
) -> Optional[str]:
    """Generates a new recipe using Azure OpenAI based on a user prompt."""
    if not openai_client or not prompt or not model_deployment_name:
        logger.error("generate_recipe_from_prompt: Missing required arguments.")
        return None

    logger.info(f"Generating new recipe with model '{model_deployment_name}' using prompt: '{prompt[:100]}...'")
    try:
        response = openai_client.chat.completions.create(
            model=model_deployment_name,
            messages=[
                {"role": "system", "content": "You are a helpful assistant that creates detailed recipes including title, ingredients, and instructions."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=max_tokens,
            temperature=temperature,
            n=1
        )

        if response.choices:
            generated_text = response.choices[0].message.content
            logger.info("Recipe generation successful.")
            return generated_text.strip() if generated_text else None
        else:
            logger.warning("OpenAI response did not contain any choices.")
            return None
    except OpenAIError as e:
        logger.error(f"OpenAI API error during recipe generation: {e}", exc_info=True)
        return None
    except Exception as e:
        logger.error(f"Unexpected error during OpenAI recipe generation: {e}", exc_info=True)
        return None

def get_text_embedding(
    openai_client: AzureOpenAI,
    text: str,
    model_deployment_name: str
) -> Optional[List[float]]:
    """Generates a vector embedding for the given text using Azure OpenAI."""
    if not openai_client or not text or not model_deployment_name:
        logger.error("get_text_embedding: Missing required arguments.")
        return None

    text_to_embed = text.replace("\n", " ")
    logger.info(f"Generating embedding with model '{model_deployment_name}' for text: '{text_to_embed[:100]}...'")
    try:
        response = openai_client.embeddings.create(
            input=[text_to_embed], # API expects a list of strings
            model=model_deployment_name
        )
        if response.data and len(response.data) > 0:
            embedding = response.data[0].embedding
            logger.info(f"Successfully generated embedding vector of dimension {len(embedding)}.")
            return embedding
        else:
            logger.warning("OpenAI embedding response did not contain data.")
            return None
    except OpenAIError as e:
        logger.error(f"OpenAI API error during text embedding: {e}", exc_info=True)
        return None
    except Exception as e:
        logger.error(f"Unexpected error during OpenAI text embedding: {e}", exc_info=True)
        return None

# --- OpenAI Ingredient Parsing Functions ---

def _parse_openai_json_lines(content: Optional[str]) -> Optional[List[Dict[str, Any]]]:
    """Helper to parse multiple JSON objects separated by newlines."""
    if not content:
        return None

    parsed_list = []
    lines = content.strip().split('\n')
    for i, line in enumerate(lines):
        line = line.strip()
        if not line:
            continue # Skip empty lines

        try:
            # Ensure line looks like JSON before parsing
            if line.startswith('{') and line.endswith('}'):
                parsed_item = json.loads(line)
                if isinstance(parsed_item, dict):
                     # Basic validation of expected keys
                     validated_item = {
                         "name": parsed_item.get("name"),
                         "quantity": parsed_item.get("quantity"),
                         "unit": parsed_item.get("unit"),
                         "notes": parsed_item.get("notes"),
                         "original": parsed_item.get("original", ""), # Try to get original
                         "food_group": parsed_item.get("food_group"), # Get new field
                         "seasonality": parsed_item.get("seasonality") # Get new field
                     }
                     # Add check for name being present?
                     if validated_item["name"]:
                          parsed_list.append(validated_item)
                     else:
                          logger.warning(f"Parsed JSON object on line {i+1} is missing 'name' key: {line}")
                else:
                     logger.warning(f"Parsed JSON on line {i+1} is not a dictionary: {line}")
            else:
                logger.warning(f"Line {i+1} does not look like valid JSON, skipping: '{line}'")
        except json.JSONDecodeError as json_err:
            logger.warning(f"Failed to parse JSON on line {i+1}: {json_err}. Line: '{line}'")
        except Exception as e:
             logger.error(f"Unexpected error parsing line {i+1} ('{line}'): {e}", exc_info=True)

    return parsed_list if parsed_list else None


def parse_ingredient_list_openai(
    openai_client: AzureOpenAI,
    ingredient_lines: List[str],
    model_deployment_name: str,
    max_tokens_multiplier: int = 85, # Slightly increased estimate for Italian terms
    temperature: float = 0.1
) -> Optional[List[Dict[str, Any]]]:
    """
    Parses a list of ingredient strings using Azure OpenAI.
    Outputs one JSON object per line in the response.
    Includes food_group and seasonality classification (Italian).
    """
    if not openai_client or not ingredient_lines or not model_deployment_name:
        logger.error("parse_ingredient_list_openai: Missing required arguments.")
        return None

    ingredients_text_block = "\n".join(ingredient_lines)
    max_tokens = max(200, len(ingredient_lines) * max_tokens_multiplier)
    logger.info(f"Parsing ingredient list ({len(ingredient_lines)} lines) using OpenAI model '{model_deployment_name}' (max_tokens={max_tokens})...")

    system_prompt = f"""
Sei un esperto parser di ingredienti per ricette. Analizza la lista di righe di ingredienti fornita.
Per OGNI riga, estrai quantità, unità di misura, nome dell'ingrediente, eventuali note di preparazione, gruppo alimentare e stagionalità.
Restituisci OGNI risultato come un **oggetto JSON separato su una singola riga**.

**Chiavi Obbligatorie per OGNI oggetto JSON:**
- "name": string (il nome principale dell'ingrediente, sii specifico)
- "quantity": float or null (la quantità numerica, usa null se non specificata come 'q.b.')
- "unit": string or null (l'unità di misura, es. "g", "ml", "cucchiaio", "pezzo", "qb", usa null se non c'è unità)
- "notes": string or null (note di preparazione come "tritato", "setacciata", "circa", "opzionale")
- "original": string (la riga di input originale per questo oggetto JSON)
- "food_group": string or null (Classifica in UNA delle seguenti categorie: {', '.join(FOOD_GROUPS_LIST_IT)}. Usa null se incerto.)
- "seasonality": string or null (Stima UNA delle seguenti stagioni: {', '.join(SEASONS_LIST_IT)}. Usa null se non applicabile.)

**Regole Formato Output:**
- Restituisci SOLO oggetti JSON.
- Ogni oggetto JSON DEVE essere sulla sua riga.
- NON restituire una lista JSON `[...]`.
- NON aggiungere testo prima del primo JSON o dopo l'ultimo JSON.
"""
    user_prompt = f"Analizza la seguente lista di ingredienti, fornendo un oggetto JSON per riga:\n---\n{ingredients_text_block}\n---"

    try:
        response = openai_client.chat.completions.create(
            model=model_deployment_name,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            max_tokens=max_tokens,
            temperature=temperature,
            n=1
        )

        if response.choices:
            content = response.choices[0].message.content
            logger.debug(f"OpenAI raw response content (list input): {content}")
            parsed_list = _parse_openai_json_lines(content) # Use the helper
            if parsed_list is not None:
                logger.info(f"Successfully parsed {len(parsed_list)} ingredients from OpenAI response (list input).")
                return parsed_list
            else:
                logger.error("Failed to parse expected JSON objects from OpenAI response (list input).")
                return None
        else:
            logger.warning("OpenAI response did not contain any choices (list input).")
            return None

    except OpenAIError as e:
        logger.error(f"OpenAI API error during ingredient list parsing: {e}", exc_info=True)
        return None
    except Exception as e:
        logger.error(f"Unexpected error during OpenAI ingredient list parsing: {e}", exc_info=True)
        return None


def parse_ingredient_block_openai(
    openai_client: AzureOpenAI,
    ingredient_text_block: str,
    model_deployment_name: str,
    max_tokens_multiplier: int = 85, # Slightly increased estimate
    temperature: float = 0.1
) -> Optional[List[Dict[str, Any]]]:
    """
    Parses a single block of text containing multiple ingredient lines using Azure OpenAI.
    Outputs one JSON object per line in the response.
    Includes food_group and seasonality classification (Italian).
    """
    if not openai_client or not ingredient_text_block or not model_deployment_name:
        logger.error("parse_ingredient_block_openai: Missing required arguments.")
        return None

    estimated_lines = max(1, len(ingredient_text_block.split(',')))
    max_tokens = max(200, estimated_lines * max_tokens_multiplier)
    logger.info(f"Parsing ingredient block using OpenAI model '{model_deployment_name}' (max_tokens={max_tokens})...")
    logger.debug(f"Input block: '{ingredient_text_block[:200]}...'")

    system_prompt = f"""
Sei un esperto parser di ingredienti per ricette. Analizza il blocco di testo fornito che contiene multipli ingredienti, potenzialmente concatenati senza chiari 'a capo' o separatori standard.
Identifica ogni ingrediente distinto menzionato. Per OGNI ingrediente distinto trovato, estrai quantità, unità di misura, nome, eventuali note di preparazione, gruppo alimentare e stagionalità.
Restituisci OGNI risultato come un **oggetto JSON separato su una singola riga**.

**Chiavi Obbligatorie per OGNI oggetto JSON:**
- "name": string (il nome principale dell'ingrediente, sii specifico)
- "quantity": float or null (la quantità numerica, usa null se non specificata)
- "unit": string or null (l'unità di misura, es. "g", "ml", "cucchiaio", "pezzo", "qb", usa null se non c'è)
- "notes": string or null (note di preparazione come "tritato", "setacciata", "circa", "opzionale")
- "original": string (la parte del testo originale corrispondente a questo ingrediente, se identificabile)
- "food_group": string or null (Classifica in UNA delle seguenti categorie: {', '.join(FOOD_GROUPS_LIST_IT)}. Usa null se incerto.)
- "seasonality": string or null (Stima UNA delle seguenti stagioni: {', '.join(SEASONS_LIST_IT)}. Usa null se non applicabile.)

**Regole Formato Output:**
- Restituisci SOLO oggetti JSON.
- Ogni oggetto JSON DEVE essere sulla sua riga.
- NON restituire una lista JSON `[...]`.
- NON aggiungere testo prima del primo JSON o dopo l'ultimo JSON.
"""
    user_prompt = f"Analizza il seguente blocco di ingredienti, fornendo un oggetto JSON per riga per ogni ingrediente trovato:\n---\n{ingredient_text_block}\n---\nJSON output:"

    try:
        response = openai_client.chat.completions.create(
            model=model_deployment_name,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            max_tokens=max_tokens,
            temperature=temperature,
            n=1
        )
        # Response Parsing Logic (using helper)
        if response.choices:
            content = response.choices[0].message.content
            logger.debug(f"OpenAI raw response content for block: {content}")
            parsed_list = _parse_openai_json_lines(content) # Use the helper
            if parsed_list is not None:
                logger.info(f"Successfully parsed {len(parsed_list)} ingredients from OpenAI response (block input).")
                return parsed_list
            else:
                logger.error("Failed to parse expected JSON objects from OpenAI response (block input).")
                return None
        else:
            logger.warning("OpenAI response did not contain choices (block input).")
            return None
    except OpenAIError as e:
        logger.error(f"OpenAI API error during ingredient block parsing: {e}", exc_info=True)
        return None
    except Exception as e:
        logger.error(f"Unexpected error during OpenAI ingredient block parsing: {e}", exc_info=True)
        return None


# --- Food Group Classification (Standalone - Updated for Italian) ---
def classify_ingredient_food_group_openai(
    openai_client: AzureOpenAI,
    ingredient_name: str,
    model_deployment_name: str,
    max_tokens: int = 25, # Slightly more tokens for Italian category names
    temperature: float = 0.0
) -> Optional[str]:
    """
    Classifies an ingredient name into a predefined food group (Italian) using OpenAI.

    Args:
        openai_client: Initialized AzureOpenAI client.
        ingredient_name: The name of the ingredient to classify (in Italian).
        model_deployment_name: The name of the deployed GPT model.

    Returns:
        The predicted food group string (Italian), or None on failure/uncertainty.
    """
    if not openai_client or not ingredient_name or not model_deployment_name:
        logger.error("classify_ingredient_food_group_openai: Missing required arguments.")
        return None

    logger.info(f"Classifying food group for: '{ingredient_name}'")
    system_prompt = f"""
Sei un esperto classificatore di alimenti. Classifica l'ingrediente fornito in UNA delle seguenti categorie:
{', '.join(FOOD_GROUPS_LIST_IT)}.
Rispondi SOLO con il nome esatto della categoria scelta dalla lista. Se sei incerto, rispondi con "Altro".
"""
    user_prompt = f"Ingrediente: {ingredient_name}\nCategoria:"

    try:
        response = openai_client.chat.completions.create(
            model=model_deployment_name,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            max_tokens=max_tokens,
            temperature=temperature,
            n=1
        )
        if response.choices:
            category = response.choices[0].message.content.strip()
            # Validate if the response is one of the allowed Italian groups
            if category in FOOD_GROUPS_LIST_IT:
                logger.info(f"Classified '{ingredient_name}' as food group: {category}")
                return category
            else:
                logger.warning(f"OpenAI returned unexpected food group '{category}' for '{ingredient_name}'. Defaulting to Altro.")
                return "Altro" # Default to Italian 'Other'
        else:
            logger.warning(f"OpenAI response for food group classification of '{ingredient_name}' had no choices.")
            return None
    except OpenAIError as e:
        logger.error(f"OpenAI API error during food group classification: {e}", exc_info=True)
        return None
    except Exception as e:
        logger.error(f"Unexpected error during food group classification: {e}", exc_info=True)
        return None

# --- TODO: Add function for URL import AI fallback ---
# def extract_recipe_from_url_ai(openai_client: AzureOpenAI, url: str) -> Optional[Dict[str, Any]]:
#     """ Extracts recipe details from URL content using OpenAI as fallback. """
#     pass

