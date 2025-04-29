# -*- coding: utf-8 -*-
"""
Functions for interacting with Azure OpenAI service (Generative AI).
Includes functions for recipe generation, embeddings, and ingredient parsing.
Updated parse_ingredient_block_openai prompt for continuous text.
"""

import logging
import json # For parsing OpenAI response
from typing import Optional, List, Dict, Any
from openai import AzureOpenAI, OpenAIError # Using the 'openai' package configured for Azure
from azure.core.exceptions import HttpResponseError

logger = logging.getLogger(__name__)

# --- OpenAI Service ---

def generate_recipe_from_prompt(
    openai_client: AzureOpenAI,
    prompt: str,
    model_deployment_name: str, # e.g., "gpt-35-turbo" deployment name
    max_tokens: int = 1500, # Increased default for potentially long recipes
    temperature: float = 0.7
) -> Optional[str]:
    """
    Generates a new recipe using Azure OpenAI based on a user prompt.

    Args:
        openai_client: Initialized AzureOpenAI client.
        prompt: The user's prompt describing the desired recipe.
        model_deployment_name: The name of the deployed GPT model to use.
        max_tokens: Max tokens for the generated response.
        temperature: Controls randomness/creativity.

    Returns:
        The generated recipe text, or None on failure.
    """
    if not openai_client or not prompt or not model_deployment_name:
         logger.error("generate_recipe_from_prompt: Missing required arguments.")
         return None

    logger.info(f"Generating new recipe with model '{model_deployment_name}' using prompt: '{prompt[:100]}...'")
    try:
        # Using Chat Completions API
        response = openai_client.chat.completions.create(
            model=model_deployment_name,
            messages=[
                {"role": "system", "content": "You are a helpful assistant that creates detailed recipes including title, ingredients, and instructions."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=max_tokens,
            temperature=temperature,
            n=1 # Generate one response
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
    model_deployment_name: str # e.g., "text-embedding-ada-002" deployment name
) -> Optional[List[float]]:
    """
    Generates a vector embedding for the given text using Azure OpenAI.

    Args:
        openai_client: Initialized AzureOpenAI client.
        text: The text to embed.
        model_deployment_name: The name of the deployed embedding model.

    Returns:
        A list of floats representing the embedding vector, or None on failure.
    """
    if not openai_client or not text or not model_deployment_name:
        logger.error("get_text_embedding: Missing required arguments.")
        return None
    # OpenAI recommends replacing newlines with spaces for embeddings
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

def parse_ingredient_list_openai(
    openai_client: AzureOpenAI,
    ingredient_lines: List[str],
    model_deployment_name: str, # e.g., "gpt-4o-mini" deployment name
    max_tokens: int = 500, # Adjust as needed per expected output size
    temperature: float = 0.1 # Lower temp for more deterministic JSON output
) -> Optional[List[Dict[str, Any]]]:
    """
    Parses a list of ingredient strings into structured data using Azure OpenAI.

    Args:
        openai_client: Initialized AzureOpenAI client.
        ingredient_lines: A list of strings, each representing one ingredient line.
        model_deployment_name: The name of the deployed GPT model to use.
        max_tokens: Max tokens for the generated JSON response.
        temperature: Controls randomness (lower is better for JSON).

    Returns:
        A list of dictionaries, each representing a parsed ingredient with keys
        'name', 'quantity', 'unit', 'notes', 'original'. Returns None on failure.
    """
    if not openai_client or not ingredient_lines or not model_deployment_name:
        logger.error("parse_ingredient_list_openai: Missing required arguments.")
        return None

    # Combine lines into a single string for the prompt, separated by newlines
    ingredients_text_block = "\n".join(ingredient_lines)
    logger.info(f"Parsing ingredient list ({len(ingredient_lines)} lines) using OpenAI model '{model_deployment_name}'...")

    system_prompt = """
        You are an expert recipe ingredient parser. Analyze the provided list of ingredient lines.
        For each line, extract the quantity, unit of measure, ingredient name, and any preparation notes.
        Return the results as a JSON list of objects. Each object must have the following keys:
        - "name": string (the main ingredient name)
        - "quantity": float or null (the numeric quantity, use null if not specified like 'q.b.')
        - "unit": string or null (the unit of measure, e.g., "g", "ml", "cup", "tsp", "piece", "qb", use null if no unit)
        - "notes": string or null (any preparation notes like "chopped", "sifted", "circa", "optional")
        - "original": string (the original input line)

        If a value is not found, use null for quantity and unit, and null or an empty string for notes.
        Ensure the output is ONLY the valid JSON list, starting with '[' and ending with ']'.
    """
    user_prompt = f"Parse the following ingredient list:\n---\n{ingredients_text_block}\n---\nJSON output:"

    try:
        response = openai_client.chat.completions.create(
            model=model_deployment_name,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            max_tokens=max_tokens,
            temperature=temperature,
            response_format={"type": "json_object"}, # Request JSON output if model supports it
            n=1
        )

        if response.choices:
            content = response.choices[0].message.content
            logger.debug(f"OpenAI raw response content: {content}")
            if content:
                try:
                    # The response might be a JSON object containing the list, e.g. {"ingredients": [...] }
                    # Or it might be the list directly. Try parsing common structures.
                    parsed_json = json.loads(content)
                    parsed_list = None
                    # Check if the root is a list
                    if isinstance(parsed_json, list):
                        parsed_list = parsed_json
                    # Check if there's a common key like 'ingredients' holding the list
                    elif isinstance(parsed_json, dict) and isinstance(parsed_json.get('ingredients'), list):
                         parsed_list = parsed_json.get('ingredients')
                    elif isinstance(parsed_json, dict) and isinstance(parsed_json.get('parsed_ingredients'), list):
                         parsed_list = parsed_json.get('parsed_ingredients')
                    else:
                         logger.warning("JSON response from OpenAI was not a list or expected dict structure.")
                         # Attempt to find a list within the dict as a fallback
                         found_list = None
                         if isinstance(parsed_json, dict):
                             for value in parsed_json.values():
                                 if isinstance(value, list):
                                     found_list = value
                                     break
                         if found_list:
                             logger.warning("Found a list under an unexpected key, using it.")
                             parsed_list = found_list
                         else:
                             parsed_list = None

                    if parsed_list is not None:
                         logger.info(f"Successfully parsed {len(parsed_list)} ingredients from OpenAI JSON response (list input).")
                         # Validate structure minimally
                         validated_list = []
                         for item in parsed_list:
                             if isinstance(item, dict):
                                 validated_list.append({
                                     "name": item.get("name"),
                                     "quantity": item.get("quantity"), # Already float or null
                                     "unit": item.get("unit"),
                                     "notes": item.get("notes"),
                                     "original": item.get("original", "") # Try to get original if provided
                                 })
                             else:
                                 logger.warning(f"Skipping invalid item in parsed list: {item}")
                         return validated_list
                    else:
                        return None # Failed to extract list from JSON

                except json.JSONDecodeError as json_err:
                    logger.error(f"Failed to parse JSON response from OpenAI: {json_err}")
                    logger.error(f"Raw content was: {content}")
                    return None
            else:
                logger.warning("OpenAI response content was empty.")
                return None
        else:
            logger.warning("OpenAI response did not contain any choices.")
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
    max_tokens: int = 500,
    temperature: float = 0.1
) -> Optional[List[Dict[str, Any]]]:
    """
    Parses a single block of text containing multiple ingredient lines
    (potentially without clear newlines) into structured data using Azure OpenAI.

    Args:
        openai_client: Initialized AzureOpenAI client.
        ingredient_text_block: A single string potentially containing multiple ingredients.
        model_deployment_name: The name of the deployed GPT model to use.
        max_tokens: Max tokens for the generated JSON response.
        temperature: Controls randomness (lower is better for JSON).

    Returns:
        A list of dictionaries, each representing a parsed ingredient with keys
        'name', 'quantity', 'unit', 'notes', 'original'. Returns None on failure.
    """
    if not openai_client or not ingredient_text_block or not model_deployment_name:
        logger.error("parse_ingredient_block_openai: Missing required arguments.")
        return None

    logger.info(f"Parsing ingredient block using OpenAI model '{model_deployment_name}'...")
    logger.debug(f"Input block: '{ingredient_text_block[:200]}...'") # Log start of block

    # System Prompt specific for text block input
    system_prompt = """
        You are an expert recipe ingredient parser. Analyze the provided text block which contains multiple ingredients, potentially concatenated without clear line breaks.
        Identify each distinct ingredient mentioned. For each ingredient, extract its quantity, unit of measure, name, and any preparation notes.
        Ingredients might be separated by commas, spaces, or context. Be flexible.
        Return the results as a JSON list of objects. Each object must have the following keys:
        - "name": string (the main ingredient name, be specific, e.g., "Farina 00", "Parmigiano Reggiano DOP")
        - "quantity": float or null (numeric quantity, use null if not specified like 'q.b.')
        - "unit": string or null (unit of measure, e.g., "g", "ml", "cup", "tsp", "piece", "qb", use null if no unit)
        - "notes": string or null (preparation notes like "chopped", "sifted", "circa", "optional")
        - "original": string (the part of the original text corresponding to this ingredient, if identifiable)

        If a value is not found, use null for quantity and unit, and null or an empty string for notes.
        Ensure the output is ONLY the valid JSON list, starting with '[' and ending with ']'.
        Example Input: "Farina 00, 100 g Burro 50g (ammorbidito) 2 Uova grandi Sale q.b."
        Example Output:
        [
        {"name": "Farina 00", "quantity": 100.0, "unit": "g", "notes": null, "original": "Farina 00, 100 g"},
        {"name": "Burro", "quantity": 50.0, "unit": "g", "notes": "ammorbidito", "original": "Burro 50g (ammorbidito)"},
        {"name": "Uova", "quantity": 2.0, "unit": null, "notes": "grandi", "original": "2 Uova grandi"},
        {"name": "Sale", "quantity": null, "unit": "qb", "notes": null, "original": "Sale q.b."}
        ]
    """
    user_prompt = f"Parse the following ingredient block:\n---\n{ingredient_text_block}\n---\nJSON output:"

    try:
        response = openai_client.chat.completions.create(
            model=model_deployment_name,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            max_tokens=max_tokens,
            temperature=temperature,
            response_format={"type": "json_object"}, # Request JSON output
            n=1
        )
        # Response Parsing Logic (same as list parser)
        if response.choices:
            content = response.choices[0].message.content
            logger.debug(f"OpenAI raw response content for block: {content}")
            if content:
                try:
                    parsed_json = json.loads(content)
                    parsed_list = None
                    if isinstance(parsed_json, list): parsed_list = parsed_json
                    elif isinstance(parsed_json, dict): # Check common keys
                        if isinstance(parsed_json.get('ingredients'), list): 
                            parsed_list = parsed_json.get('ingredients')
                        elif isinstance(parsed_json.get('parsed_ingredients'), list): 
                            parsed_list = parsed_json.get('parsed_ingredients')
                        else: # Fallback: find first list in dict values
                            for value in parsed_json.values():
                                if isinstance(value, list): parsed_list = value; break
                    if parsed_list is not None:
                        logger.info(f"Successfully parsed {len(parsed_list)} ingredients from OpenAI JSON response (block input).")
                        validated_list = [
                            {
                                "name": item.get("name"), 
                                "quantity": item.get("quantity"), 
                                "unit": item.get("unit"), 
                                "notes": item.get("notes"), 
                                "original": item.get("original", "")
                            } 
                            for item in parsed_list if isinstance(item, dict)
                        ]
                        return validated_list
                    else: 
                        logger.warning("JSON response from OpenAI was not a list or expected dict structure."); return None
                except json.JSONDecodeError as json_err: 
                    logger.error(f"Failed to parse JSON response: {json_err}\nRaw content: {content}"); return None
            else: 
                logger.warning("OpenAI response content was empty."); return None
        else: 
            logger.warning("OpenAI response did not contain choices."); return None
    except OpenAIError as e: 
        logger.error(f"OpenAI API error during ingredient block parsing: {e}", exc_info=True); return None
    except Exception as e: 
        logger.error(f"Unexpected error during OpenAI ingredient block parsing: {e}", exc_info=True); return None


# --- TODO: Add function for URL import AI fallback ---
# def extract_recipe_from_url_ai(openai_client: AzureOpenAI, url: str) -> Optional[Dict[str, Any]]:
#     """ Extracts recipe details from URL content using OpenAI as fallback. """
#     pass

# --- TODO: Add function for Food Group Classification ---
# def classify_ingredient_food_group_openai(openai_client: AzureOpenAI, ingredient_name: str, model_deployment_name: str) -> Optional[str]:
#     """ Classifies an ingredient name into a food group using OpenAI. """
#     pass

