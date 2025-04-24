# -*- coding: utf-8 -*-
"""
Utility functions for the Mirai Cook application.
Includes functions for parsing ingredient strings, sanitization, etc.
Fixed regex flags for case-insensitivity.
"""

import re
import logging
from typing import Dict, Optional, Union, Tuple
from unidecode import unidecode # For robust character handling

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
    'piece', 'pieces', 'pz', # Added pz
    'can', 'cans', 'scatola', # Added scatola
    'package', 'packages', 'confezione', # Added confezione
    'bunch', 'bunches', 'mazzetto', # Added mazzetto
    'sprig', 'sprigs', 'rametto', # Added rametto
    # Italian units
    'cucchiaio', 'cucchiai', 'cucchiaino', 'cucchiaini',
    'pizzico', 'spicchio', 'spicchi', 'fetta', 'fette', 'bicchiere', 'bicchieri',
    'etto', 'etti', 'hg',
    'qb', 'q.b', 'q.b.' # Quanto basta
]
# Create a regex pattern for units (case-insensitive matching will be handled by flag)
# Removed (?i) from here
UNIT_PATTERN = r'\b(?:' + '|'.join(re.escape(unit) for unit in COMMON_UNITS) + r')\b\.?' # Allow optional dot

# Regex pattern for numbers, including fractions and decimals
NUMBER_PATTERN = r'(\d+\s*\/\s*\d+|\d+\s+\d+\s*\/\s*\d+|\d*\.\d+|\d+)' # Captures the number part

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
        return parsed # Return empty if line is empty

    # --- Pre-processing ---
    notes_match = re.search(r'\((.*?)\)', line)
    if notes_match:
        parsed["notes"] = notes_match.group(1).strip()
        line = re.sub(r'\(.*?\)', '', line).strip()
    line_parts = re.split(r'\s*[,-]\s*', line, 1)
    line = line_parts[0].strip()
    if len(line_parts) > 1 and parsed["notes"] is None:
        parsed["notes"] = line_parts[1].strip()


    # --- Regex Matching Attempts (Order Matters) ---

    # Pattern 1: Number Unit Name (e.g., "100 g flour", "1 1/2 cup sugar")
    # Use flags=re.IGNORECASE instead of inline (?i)
    pattern1_regex = rf'^\s*({NUMBER_PATTERN})\s*({UNIT_PATTERN})\s+(.*)$'
    match = re.match(pattern1_regex, line, flags=re.IGNORECASE)
    if match:
        logger.debug("Matched Pattern 1: Number Unit Name")
        parsed["quantity"] = _parse_quantity(match.group(1))
        parsed["unit"] = match.group(3).strip().rstrip('.').lower() # Group 3 is UNIT_PATTERN
        parsed["name"] = match.group(4).strip() # Group 4 is the rest
        if parsed["unit"] == 'q.b.': parsed["unit"] = 'qb'
        return parsed

    # Pattern 2: Number Name (No recognized unit found after number)
    # No case flag needed here as UNIT_PATTERN is not used
    pattern2_regex = rf'^\s*({NUMBER_PATTERN})\s+([^\d].*)$'
    match = re.match(pattern2_regex, line)
    if match:
        logger.debug("Matched Pattern 2: Number Name (Unit Optional/Implicit)")
        parsed["quantity"] = _parse_quantity(match.group(1))
        parsed["unit"] = None
        parsed["name"] = match.group(3).strip() # Group 3 is the rest
        return parsed

    # Pattern 3: Name Number [Unit] [Notes]
    # Use flags=re.IGNORECASE for the optional unit part
    pattern3_regex = rf'^(.*?)\s+({NUMBER_PATTERN})\s*({UNIT_PATTERN})?\s*(.*)$'
    match = re.match(pattern3_regex, line, flags=re.IGNORECASE)
    if match:
        logger.debug("Matched Pattern 3: Name Number [Unit] [Notes]")
        potential_name = match.group(1).strip()
        potential_qty = _parse_quantity(match.group(2))
        potential_unit = match.group(4) # Group 4 is UNIT_PATTERN capture
        remaining_text = match.group(5).strip()

        # Check if the potential name makes sense (not just a unit)
        # Compare lowercase against lowercase list
        if potential_name.lower() not in COMMON_UNITS:
            parsed["name"] = potential_name
            parsed["quantity"] = potential_qty
            if potential_unit:
                parsed["unit"] = potential_unit.strip().rstrip('.').lower()
                if parsed["unit"] == 'q.b.': parsed["unit"] = 'qb'
            else:
                parsed["unit"] = None # No unit explicitly matched after number

            if remaining_text and parsed["notes"] is None: parsed["notes"] = remaining_text
            elif remaining_text and parsed["notes"] is not None: parsed["notes"] = f"{parsed['notes']}, {remaining_text}"
            return parsed
        else:
            logger.debug("Pattern 3 potential name matched a common unit, skipping.")


    # Pattern 4: Name Number (No Unit after number, e.g., "Eggs 2")
    # No case flag needed
    pattern4_regex = rf'^(.*?)\s+({NUMBER_PATTERN})\s*$'
    match = re.match(pattern4_regex, line)
    if match:
        logger.debug("Matched Pattern 4: Name Number")
        potential_name = match.group(1).strip()
        if potential_name.lower() not in COMMON_UNITS:
            parsed["name"] = potential_name
            parsed["quantity"] = _parse_quantity(match.group(2))
            parsed["unit"] = None
            if parsed["notes"] is None and notes_match: parsed["notes"] = notes_match.group(1).strip()
            return parsed
        else:
             logger.debug("Pattern 4 potential name matched a common unit, skipping.")

    # Pattern 5: Unit Name (No Number, e.g., "pinch of salt", "qb sale") - Renumbered
    # Use flags=re.IGNORECASE
    pattern5_regex = rf'^\s*({UNIT_PATTERN})\s+(?:of\s+)?(.*)$'
    match = re.match(pattern5_regex, line, flags=re.IGNORECASE)
    if match:
        logger.debug("Matched Pattern 5: Unit Name")
        parsed["quantity"] = None
        parsed["unit"] = match.group(1).strip().rstrip('.').lower() # Group 1 is UNIT_PATTERN
        parsed["name"] = match.group(2).strip() # Group 2 is the rest
        if parsed["unit"] == 'q.b.': parsed["unit"] = 'qb'
        return parsed

    # --- Fallback ---
    logger.debug(f"No specific pattern matched for '{line}'. Assigning full string to name.")
    parsed["name"] = line
    if parsed["notes"] is None and notes_match:
         parsed["notes"] = notes_match.group(1).strip()

    return parsed


def _parse_quantity(qty_str: str) -> Optional[float]:
    """Helper function to parse quantity strings into floats."""
    qty_str = qty_str.strip()
    try:
        if '/' not in qty_str: return float(qty_str)
        if ' ' in qty_str:
            parts = qty_str.split(' ', 1)
            whole = int(parts[0])
            num, den = map(int, parts[1].split('/'))
            if den == 0: return None
            return whole + (num / den)
        else:
            num, den = map(int, qty_str.split('/'))
            if den == 0: return None
            return num / den
    except (ValueError, ZeroDivisionError, IndexError) as e:
        logger.warning(f"Could not parse quantity string: '{qty_str}', Error: {e}")
        return None

# --- NEW FUNCTION ---
def parse_servings(yields_string: Optional[str]) -> Optional[int]:
    """
    Extracts the first integer number found in a yields/servings string.
    """
    if not yields_string: return None
    numbers = re.findall(r'\d+', yields_string)
    if numbers:
        try: return int(numbers[0])
        except ValueError: logger.warning(f"Could not convert found number to integer in yields string: '{yields_string}'"); return None
    else: logger.debug(f"No number found in yields string: '{yields_string}'"); return None

# --- Example Usage (for testing this module directly) ---
if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    test_ingredients = [
        "2 cups all-purpose flour, sifted", "1 1/2 tsp baking soda", "1/2 cup granulated sugar",
        "100g butter, softened", "2 large eggs", "1 lemon (zest and juice)", "Salt q.b.",
        "A pinch of nutmeg", "1 kg potatoes", "1.5 liters water", "1/4 lb ground beef",
        "1 can (14.5 oz) diced tomatoes", "3 cloves garlic, minced", "1/2 etto prosciutto cotto",
        "Sale e pepe", "Brodo vegetale", "2 mele", "100 farina 00", "Flour 100 g",
        "Eggs 2 large", "Olive Oil 2 tbsp", "Basil 1 bunch", "g 100 farina", "1 TSP Salt" # Test case insensitivity
    ]
    print("--- Testing Ingredient Parser ---")
    for item in test_ingredients:
        parsed = parse_ingredient_string(item)
        print(f"\nOriginal: '{item}'")
        print(f"Parsed:   {parsed}")

    test_yields = ["Serves 4", "Makes 6-8 servings", "Yields: 1 loaf", "2 Porzioni", "Per 1 persona"]
    print("\n--- Testing Servings Parser ---")
    for item in test_yields:
        servings = parse_servings(item)
        print(f"Original: '{item}' -> Parsed Servings: {servings}")

