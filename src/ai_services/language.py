# -*- coding: utf-8 -*-
"""
Functions for interacting with Azure AI Language service (Text Analytics).
Includes custom classification and NER for ingredient extraction.
"""

import logging
import re
from typing import Optional, List, Dict, Any, Union # Added Union
from azure.core.exceptions import HttpResponseError
from azure.ai.textanalytics import TextAnalyticsClient

# Import helper from utils
try:
    # Assuming utils.py is one level up
    from ..utils import parse_quantity_and_unit
except ImportError:
    # Fallback for direct execution or different structure
    from utils import parse_quantity_and_unit
    logging.warning("Could not perform relative import for utils in language.py.")

logger = logging.getLogger(__name__)

# --- Language Service (Classification) ---
def classify_recipe_category(
    language_client: TextAnalyticsClient,
    recipe_text: str,
    project_name: str, # Required for custom classification
    deployment_name: str # Required for custom classification
) -> Optional[Dict[str, float]]:
    """
    Classifies the recipe text into predefined categories using a custom
    single-label text classification model deployed in Azure AI Language.
    """
    # ... (Implementation remains the same as provided in the context) ...
    if not language_client or not recipe_text or not project_name or not deployment_name: logger.error("classify_recipe_category: Missing args."); return None
    logger.info(f"Starting category classification (Project: {project_name}, Deployment: {deployment_name}).")
    try:
        documents = [recipe_text]; poller = language_client.begin_single_label_classify(documents, project_name=project_name, deployment_name=deployment_name)
        document_results = poller.result(); top_category = None; highest_confidence = 0.0
        for doc, classification_result in zip(documents, document_results):
            if classification_result.kind == "CustomSingleLabelClassification":
                classification = classification_result.classification
                logger.info(f"Predicted category: '{classification.category}' (Confidence: {classification.confidence_score:.2f})")
                top_category = classification.category; highest_confidence = classification.confidence_score
            elif classification_result.is_error is True: logger.error(f"Error classifying: {classification_result.error.message}"); return None
        if top_category: return {"category": top_category, "confidence": highest_confidence}
        else: logger.warning("No category confidently determined."); return None
    except Exception as e: logger.error(f"Error during classification: {e}", exc_info=True); return None


# --- Language Service (NER for Ingredients) ---

# --- NEW Single Line NER Parser ---
def parse_single_ingredient_ner(
    language_client: TextAnalyticsClient,
    line: str
) -> Dict[str, Optional[Union[float, str]]]:
    """
    Attempts to parse a SINGLE ingredient line into quantity, unit, and name
    using Azure AI Language Named Entity Recognition (NER).

    Args:
        language_client: Initialized TextAnalyticsClient.
        line (str): The raw ingredient string.

    Returns:
        Dict: A dictionary with keys 'quantity', 'unit', 'name', 'notes', 'original'.
              Returns parsed values based on NER results. Falls back to basic assignment
              if NER fails or doesn't provide useful entities.
    """
    original_line = line.strip()
    logger.debug(f"Parsing single ingredient line via NER: '{original_line}'")

    # Default return structure, matching the regex parser output
    parsed = {
        "quantity": None,
        "unit": None,
        "name": None,
        "notes": None,
        "original": original_line
    }
    if not original_line:
        return parsed

    # Pre-processing (extract notes in parentheses)
    notes_match = re.search(r'\((.*?)\)', line)
    if notes_match:
        parsed["notes"] = notes_match.group(1).strip()
        line_for_ner = re.sub(r'\(.*?\)', '', line).strip()
    else:
        line_for_ner = line

    if not line_for_ner: # If only notes were present
        parsed["name"] = original_line # Assign original as name
        return parsed

    # Call Azure AI Language NER
    try:
        documents = [line_for_ner]
        result = language_client.recognize_entities(documents=documents)[0] # Process first doc result

        if result.is_error:
            logger.error(f"NER API error for line '{line_for_ner}': Code={result.error.code}, Message={result.error.message}")
            parsed["name"] = original_line # Fallback
            return parsed

        # Process Recognized Entities
        entities = sorted(result.entities, key=lambda e: e.offset) # Sort by position
        logger.debug(f"NER Entities for '{line_for_ner}': {[(e.text, e.category) for e in entities]}")

        extracted_name_parts = []
        found_quantity = None
        found_unit = None
        quantity_entity_text = None # Store the text of the quantity entity

        # Find the first parsable Quantity/Dimension entity
        for entity in entities:
            if entity.category in ["Quantity", "Dimension"]:
                qty, unit = parse_quantity_and_unit(entity.text) # Use helper from utils
                if qty is not None or unit is not None:
                    # If we found a valid quantity or unit, store the entity text
                    found_quantity = qty
                    found_unit = unit
                    quantity_entity_text = entity.text # Remember the text
                    logger.debug(f"Found Qty/Unit Entity: text='{entity.text}', parsed_qty={qty}, parsed_unit={unit}")
                    break # Take the first one found

        # Collect name parts (Product, Food, Other, Skill), excluding the quantity text
        for entity in entities:
            # Skip the quantity entity we already processed
            if quantity_entity_text and entity.text == quantity_entity_text and entity.category in ["Quantity", "Dimension"]:
                continue
            # Collect relevant categories for the name
            if entity.category in ["Product", "Food", "Other", "Skill", "Location", "Person", "Organization", "Event"]:
                 extracted_name_parts.append(entity.text)

        parsed["quantity"] = found_quantity
        parsed["unit"] = found_unit
        if extracted_name_parts:
            parsed["name"] = " ".join(extracted_name_parts).strip()
        else:
            # Fallback if no specific name entities found
            name_fallback = line_for_ner
            if quantity_entity_text: # Try removing quantity text from the line
                name_fallback = name_fallback.replace(quantity_entity_text, "").strip()
            parsed["name"] = name_fallback if name_fallback else original_line # Use processed line or original

        # Final cleanup on name if needed
        if parsed["name"]:
            parsed["name"] = " ".join(parsed["name"].split()) # Remove extra spaces

        logger.debug(f"Parsed via NER: Qty={parsed['quantity']}, Unit='{parsed['unit']}', Name='{parsed['name']}', Notes='{parsed['notes']}'")
        return parsed

    except ImportError:
         logger.error("Failed to import TextAnalyticsClient. Azure AI Language features unavailable.")
         parsed["name"] = original_line # Fallback
         return parsed
    except Exception as e:
        logger.error(f"Unexpected error during single NER parsing for line '{line}': {e}", exc_info=True)
        parsed["name"] = original_line # Fallback
        return parsed


# --- Block NER Function (Consider Refactoring/Removing) ---
# This might call the single line parser now
def extract_structured_ingredients_ner_block(
    language_client: TextAnalyticsClient,
    ingredient_text_block: str
) -> Optional[List[Dict[str, Any]]]:
    """
    Extracts structured ingredients from a BLOCK of text using NER.
    Currently calls the single-line parser for each line.

    Args:
        language_client: Initialized TextAnalyticsClient.
        ingredient_text_block: A string containing multiple ingredient lines.

    Returns:
        Optional[List[Dict[str, Any]]]: List of parsed ingredient dicts.
    """
    if not language_client or not ingredient_text_block:
        logger.error("extract_structured_ingredients_ner_block: Missing language client or text block.")
        return None

    logger.info("Attempting structured ingredient extraction via NER (Block -> Line-by-Line)...")
    parsed_list = []
    for line in ingredient_text_block.strip().split('\n'):
        if line.strip():
            # Call the single line parser
            parsed_line = parse_single_ingredient_ner(language_client, line)
            parsed_list.append(parsed_line)

    logger.info(f"Block NER processing resulted in {len(parsed_list)} structured ingredients.")
    return parsed_list if parsed_list else None

