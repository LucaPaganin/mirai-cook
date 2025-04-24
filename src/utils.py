# -*- coding: utf-8 -*-
"""
Utility functions for the Mirai Cook application.
Includes functions for parsing ingredient strings, sanitization, etc.
Fixed regex flags for case-insensitivity.
"""

import re
import logging
from typing import Dict, Optional, Union, Tuple
from unidecode import unidecode  # For robust character handling

# Configure logging
logger = logging.getLogger(__name__)

# --- Constants for Parsing ---
# Common units (expand this list!)
COMMON_UNITS = [
    'g', 'gr', 'gram', 'grams', 'kg', 'kilogram', 'kilograms',
    'ml', 'milliliter', 'milliliters', 'l', 'liter', 'liters',
    'oz', 'ounce', 'ounces', 'lb', 'pound', 'pounds',
    'tsp', 'teaspoon', 'teaspoons',
    'tbsp', 'tablespoon', 'tablespoons',
    'cup', 'cups',
    'pinch', 'pinches',
    'clove', 'cloves',
    'slice', 'slices',
    'piece', 'pieces', 'pz',  # Added pz
    'can', 'cans', 'scatola',  # Added scatola
    'package', 'packages', 'confezione',  # Added confezione
    'bunch', 'bunches', 'mazzetto',  # Added mazzetto
    'sprig', 'sprigs', 'rametto',  # Added rametto
    # Italian units
    'cucchiaio', 'cucchiai', 'cucchiaino', 'cucchiaini',
    'pizzico', 'spicchio', 'spicchi', 'fetta', 'fette', 'bicchiere', 'bicchieri',
    'etto', 'etti', 'hg',
    'qb', 'q.b', 'q.b.'  # Quanto basta
]
# Create a regex pattern for units (case-insensitive matching will be handled by flag)
# Removed (?i) from here
# Build a regex pattern for units (case-insensitive, allows optional trailing dot)
UNIT_PATTERN = r'(?:' + '|'.join(re.escape(unit) for unit in COMMON_UNITS) + r')\.?'

# Regex pattern for numbers, including fractions and decimals
# Captures the number part
NUMBER_PATTERN = r'(?:\d*[\.,]\d+|\d+\s*\/\s*\d+|\d+\s+\d+\s*\/\s*\d+|\d+)'

# --- Parsing Function ---


def parse_ingredient_string(line: str) -> Dict[str, Optional[Union[float, str]]]:
    """
    Attempts to parse a single ingredient line into quantity, unit, and name
    using regular expressions for common patterns. Handles optional units
    and different orders. Uses re.IGNORECASE for unit matching.

    Args:
        line (str): The raw ingredient string (e.g., "2 1/2 cups flour, sifted", "Flour 100 g").

    Returns:
        Dict: A dictionary with keys 'quantity', 'unit', 'name', 'notes', 'original'.
              Quantity is float, unit/name/notes are strings or None.
    """
    original_line = line.strip()
    logger.debug(f"Parsing ingredient line: '{original_line}'")

    # Default return structure
    parsed = {
        "quantity": None,
        "unit": None,
        "name": None,
        "notes": None,
        "original": original_line
    }
    if not original_line:
        return parsed  # Return empty if line is empty

    # --- Pre-processing ---
    notes_match = re.search(r'\((.*?)\)', line)
    if notes_match:
        parsed["notes"] = notes_match.group(1).strip()
        line = re.sub(r'\(.*?\)', '', line).strip()
    # Only split on dashes or commas NOT between digits
    line_parts = re.split(r'\s*(?<!\d),(?!\d)\s*|\s*-\s*', line, 1)
    line = line_parts[0].strip()
    if len(line_parts) > 1 and parsed["notes"] is None:
        parsed["notes"] = line_parts[1].strip()

    # --- Regex Matching Attempts (Order Matters) ---

    # Pattern 1: Number Unit Name (e.g., "100 g flour", "1 1/2 cup sugar")
    qty_unit_name_pattern = (
        rf'^\s*'
        rf'(?P<quantity>{NUMBER_PATTERN})\s*'
        rf'(?P<unit>{UNIT_PATTERN})\s+'
        rf'(?P<name>.*)$'
    )
    match = re.match(qty_unit_name_pattern, line, flags=re.IGNORECASE)
    if match:
        logger.debug("Matched Pattern 1: Number Unit Name")
        parsed["quantity"] = _parse_quantity(match.group("quantity"))
        parsed["unit"] = match.group("unit").strip().rstrip('.').lower()
        parsed["name"] = match.group("name").strip()
        if parsed["unit"] == 'q.b.':
            parsed["unit"] = 'qb'
        return parsed
    
    # Pattern X: Unit Quantity Name (e.g., "g 100 farina", "kg 1 zucchero")
    unit_qty_name_pattern = (
        rf'^\s*'
        rf'(?P<unit>{UNIT_PATTERN})\s*'
        rf'(?P<quantity>{NUMBER_PATTERN})\s+'
        rf'(?P<name>.*)$'
    )
    match = re.match(unit_qty_name_pattern, line, flags=re.IGNORECASE)
    if match:
        logger.debug("Matched Pattern X: Unit Quantity Name")
        parsed["unit"] = match.group("unit").strip().rstrip('.').lower()
        if parsed["unit"] == 'q.b.':
            parsed["unit"] = 'qb'
        parsed["quantity"] = _parse_quantity(match.group("quantity"))
        parsed["name"] = match.group("name").strip()
        return parsed

    # Pattern 2: Number Name (No recognized unit found after number)
    qty_name_pattern = (
        rf'^\s*'
        rf'(?P<quantity>{NUMBER_PATTERN})\s+'
        rf'(?P<name>[^\d].*)$'
    )
    match = re.match(qty_name_pattern, line)
    if match:
        logger.debug("Matched Pattern 2: Number Name (Unit Optional/Implicit)")
        parsed["quantity"] = _parse_quantity(match.group("quantity"))
        parsed["unit"] = None
        parsed["name"] = match.group("name").strip()
        return parsed

    # Pattern 3: Name Number [Unit] [Notes]
    name_qty_unit_notes_pattern = (
        rf'^(?P<name>.*?)\s+'
        rf'(?P<quantity>{NUMBER_PATTERN})\s*'
        rf'(?P<unit>{UNIT_PATTERN})?\s*'
        rf'(?P<notes>.*)$'
    )
    match = re.match(name_qty_unit_notes_pattern, line, flags=re.IGNORECASE)
    if match:
        logger.debug("Matched Pattern 3: Name Number [Unit] [Notes]")
        potential_name = match.group("name").strip()
        potential_qty = _parse_quantity(match.group("quantity"))
        potential_unit = match.group("unit")
        remaining_text = match.group("notes").strip()

        if potential_name.lower() not in COMMON_UNITS:
            parsed["name"] = potential_name
            parsed["quantity"] = potential_qty
            if potential_unit:
                parsed["unit"] = potential_unit.strip().rstrip('.').lower()
                if parsed["unit"] == 'q.b.':
                    parsed["unit"] = 'qb'
            else:
                parsed["unit"] = None

            if remaining_text and parsed["notes"] is None:
                parsed["notes"] = remaining_text
            elif remaining_text and parsed["notes"] is not None:
                parsed["notes"] = f"{parsed['notes']}, {remaining_text}"
            return parsed
        else:
            logger.debug(
                "Pattern 3 potential name matched a common unit, skipping.")

    # Pattern 4: Name Number (No Unit after number, e.g., "Eggs 2")
    name_qty_pattern = (
        rf'^(?P<name>.*?)\s+'
        rf'(?P<quantity>{NUMBER_PATTERN})\s*$'
    )
    match = re.match(name_qty_pattern, line)
    if match:
        logger.debug("Matched Pattern 4: Name Number")
        potential_name = match.group("name").strip()
        if potential_name.lower() not in COMMON_UNITS:
            parsed["name"] = potential_name
            parsed["quantity"] = _parse_quantity(match.group("quantity"))
            parsed["unit"] = None
            if parsed["notes"] is None and notes_match:
                parsed["notes"] = notes_match.group(1).strip()
            return parsed
        else:
            logger.debug(
                "Pattern 4 potential name matched a common unit, skipping.")

    # Pattern 5: Unit Name (No Number, e.g., "pinch of salt", "qb sale")
    unit_name_pattern = (
        rf'^\s*'
        rf'(?P<unit>{UNIT_PATTERN})\s+'
        rf'(?:of\s+)?'
        rf'(?P<name>.*)$'
    )
    match = re.match(unit_name_pattern, line, flags=re.IGNORECASE)
    if match:
        logger.debug("Matched Pattern 5: Unit Name")
        parsed["quantity"] = None
        parsed["unit"] = match.group("unit").strip().rstrip('.').lower()
        parsed["name"] = match.group("name").strip()
        if parsed["unit"] == 'q.b.':
            parsed["unit"] = 'qb'
        return parsed

    # --- Fallback ---
    logger.debug(
        f"No specific pattern matched for '{line}'. Assigning full string to name.")
    parsed["name"] = line
    if parsed["notes"] is None and notes_match:
        parsed["notes"] = notes_match.group(1).strip()

    return parsed


def _parse_quantity(qty_str: str) -> Optional[float]:
    """Helper function to parse quantity strings into floats."""
    qty_str = qty_str.strip().replace(',', '.')
    try:
        if '/' not in qty_str:
            return float(qty_str)
        if ' ' in qty_str:
            parts = qty_str.split(' ', 1)
            whole = int(parts[0])
            num, den = map(int, parts[1].split('/'))
            if den == 0:
                return None
            return whole + (num / den)
        else:
            num, den = map(int, qty_str.split('/'))
            if den == 0:
                return None
            return num / den
    except (ValueError, ZeroDivisionError, IndexError) as e:
        logger.warning(
            f"Could not parse quantity string: '{qty_str}', Error: {e}")
        return None

# --- NEW FUNCTION ---


def parse_servings(yields_string: Optional[str]) -> Optional[int]:
    """
    Extracts the first integer number found in a yields/servings string.
    """
    if not yields_string:
        return None
    numbers = re.findall(r'\d+', yields_string)
    if numbers:
        try:
            return int(numbers[0])
        except ValueError:
            logger.warning(
                f"Could not convert found number to integer in yields string: '{yields_string}'")
            return None
    else:
        logger.debug(f"No number found in yields string: '{yields_string}'")
        return None


# --- Example Usage (for testing this module directly) ---
if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    test_ingredients = [
        "100g burro, ammorbidito",
        "g 100 farina",
        "Cipolle dorate 1,5 kg",
        "2 tazze di farina 00, setacciata",
        "1 1/2 cucchiaino di bicarbonato di sodio",
        "1/2 tazza di zucchero semolato",
        "2 uova grandi",
        "1 limone (scorza e succo)",
        "Sale q.b.",
        "Un pizzico di noce moscata",
        "1 kg patate",
        "1,5 litri d'acqua",
        "1/4 lb carne macinata di manzo",
        "1 lattina (14,5 oz) di pomodori a cubetti",
        "3 spicchi d'aglio, tritati",
        "1/2 etto prosciutto cotto",
        "Sale e pepe",
        "Brodo vegetale",
        "2 mele",
        "100 farina 00",
        "Farina 100 g",
        # Test case insensitivity
        "Uova 2 grandi",
        "Olio d'oliva 2 cucchiai",
        "Basilico 1 mazzetto",
        "1 CUCCHIAINO Sale"
    ]
    print("--- Testing Ingredient Parser ---")
    for item in test_ingredients:
        parsed = parse_ingredient_string(item)
        print(f"\nOriginal: '{item}'")
        print(f"Parsed:   {parsed}")

    test_yields = ["Serves 4", "Makes 6-8 servings",
                   "Yields: 1 loaf", "2 Porzioni", "Per 1 persona"]
    print("\n--- Testing Servings Parser ---")
    for item in test_yields:
        servings = parse_servings(item)
        print(f"Original: '{item}' -> Parsed Servings: {servings}")


def process_doc_intel_analyze_result(
    doc_intel_analyze_result: Dict[str, Union[str, Dict[str, str]]],
    selected_model_id: str
) -> Dict[str, Optional[Union[str, None]]]:
    """
    Process the document intelligence analyze result to extract the text and language.
    """
    if not doc_intel_analyze_result:
        return None, None

    if selected_model_id.startswith("cucina_facile"):
        pass
    else:
        # Extract text and language from the result
        text = doc_intel_analyze_result.get("text", None)
        language = doc_intel_analyze_result.get("language", None)

        # If the result is a dictionary, extract the text and language from it
        if isinstance(doc_intel_analyze_result, dict):
            text = doc_intel_analyze_result.get("text", text)
            language = doc_intel_analyze_result.get("language", language)
        
        result = {
            "text": text,
            "language": language
        }

    return result