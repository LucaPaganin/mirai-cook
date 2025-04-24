# -*- coding: utf-8 -*-
"""
Utility functions for the Mirai Cook application.
Includes functions for parsing ingredient strings, sanitization, etc.
Fixed regex flags for case-insensitivity.
"""

import re
import logging
from typing import Dict, List, Optional, Union, Tuple
from unidecode import unidecode  # For robust character handling
try:
    from units import COMMON_UNITS  # Assuming this is a list of common units
except (ImportError, ModuleNotFoundError):
    from src.units import COMMON_UNITS  # Adjust the import path as necessary

# Configure logging
logger = logging.getLogger(__name__)


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
    else:
        line = original_line.strip()
    # # Only split on dashes or commas NOT between digits

    # --- Pattern dictionary ---
    def process_number_unit_name(match):
        parsed["quantity"] = _parse_quantity(match.group("quantity"))
        parsed["unit"] = match.group("unit").strip().rstrip('.').lower()
        parsed["name"] = match.group("name").strip()
        if parsed["unit"] == 'q.b.':
            parsed["unit"] = 'qb'
        return parsed

    def process_unit_quantity_name(match):
        parsed["unit"] = match.group("unit").strip().rstrip('.').lower()
        if parsed["unit"] == 'q.b.':
            parsed["unit"] = 'qb'
        parsed["quantity"] = _parse_quantity(match.group("quantity"))
        parsed["name"] = match.group("name").strip()
        return parsed

    def process_number_name(match):
        parsed["quantity"] = _parse_quantity(match.group("quantity"))
        parsed["unit"] = None
        parsed["name"] = match.group("name").strip()
        return parsed

    def process_name_number_unit_notes(match):
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
            return None

    def process_name_number(match):
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
            return None

    def process_unit_name(match):
        parsed["quantity"] = None
        parsed["unit"] = match.group("unit").strip().rstrip('.').lower()
        parsed["name"] = match.group("name").strip()
        if parsed["unit"] == 'q.b.':
            parsed["unit"] = 'qb'
        return parsed

    patterns = [
        {
            "name": "Number Unit Name",
            "regex": rf'^\s*(?P<quantity>{NUMBER_PATTERN})\s*(?P<unit>{UNIT_PATTERN})\s+(?P<name>.*)$',
            "flags": re.IGNORECASE,
            "processor": process_number_unit_name
        },
        {
            "name": "Unit Quantity Name",
            "regex": rf'^\s*(?P<unit>{UNIT_PATTERN})\s*(?P<quantity>{NUMBER_PATTERN})\s+(?P<name>.*)$',
            "flags": re.IGNORECASE,
            "processor": process_unit_quantity_name
        },
        {
            "name": "Number Name (No recognized unit found after number)",
            "regex": rf'^\s*(?P<quantity>{NUMBER_PATTERN})\s+(?P<name>[^\d].*)$',
            "flags": 0,
            "processor": process_number_name
        },
        {
            "name": "Name[,] Number [Unit] [Notes]",
            "regex": rf'^(?P<name>.*?),?\s+(?P<quantity>{NUMBER_PATTERN})\s*(?P<unit>{UNIT_PATTERN})?\s*(?P<notes>.*)$',
            "flags": re.IGNORECASE,
            "processor": process_name_number_unit_notes
        },
        {
            "name": "Name Number (No Unit after number)",
            "regex": rf'^(?P<name>.*?)\s+(?P<quantity>{NUMBER_PATTERN})\s*$',
            "flags": 0,
            "processor": process_name_number
        },
        {
            "name": "Unit Name (No Number)",
            "regex": rf'^\s*(?P<unit>{UNIT_PATTERN})\s+(?:of\s+)?(?P<name>.*)$',
            "flags": re.IGNORECASE,
            "processor": process_unit_name
        }
    ]

    # --- Try patterns in order ---
    for pat in patterns:
        match = re.match(pat["regex"], line, flags=pat["flags"])
        if match:
            logger.debug(f"Matched Pattern: {pat['name']}")
            result = pat["processor"](match)
            if result is not None:
                return result

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


def parse_quantity_and_unit(quantity_text: str) -> Optional[Dict[str, str]]:
    """
    Separates the quantity from its unit of measure (e.g., "350 g" -> {"value": "350", "unit": "g"}).
    Handles both dot and comma as decimal separators, and also fractional quantities like "1/2".
    """
    # First, check for fractions like 1/2, 3/4
    fraction_pattern = r'(?P<value>\d+\/\d+)'  # Detects fractions (e.g., 1/2, 3/4)
    match_fraction = re.match(fraction_pattern, quantity_text.strip())
    
    if match_fraction:
        # Convert fraction (e.g., 1/2) into a decimal value (e.g., 0.5)
        fraction = match_fraction.group("value")
        numerator, denominator = map(int, fraction.split("/"))
        decimal_value = numerator / denominator
        return {"value": str(decimal_value), "unit": None}  # No unit, or we could return a default unit

    # Otherwise, handle regular quantity + unit (e.g., "350 g", "1.5 dl")
    match = re.match(r'(?P<value>\d+([,.\/]?\d*)?)\s*(?P<unit>\D+)', quantity_text.strip())
    
    if match:
        # Return the value as string (replace comma with dot for decimal consistency)
        value = match.group("value").replace(",", ".")
        unit = match.group("unit").strip()
        return {"value": value, "unit": unit}
    
    return None


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

def extract_max_number(time_str: str) -> float:
    """
    Extracts the maximum number from a time string like '15-20 min'.
    Handles leading/trailing spaces and multiple spaces.
    Returns the number as float, or None if not found.
    """
    if not time_str or not isinstance(time_str, str):
        return None
    # Sanitize: strip and collapse multiple spaces
    sanitized = re.sub(r'\s+', ' ', time_str.strip())
    # Find all numbers (integers or decimals)
    numbers = re.findall(r'\d+(?:\.\d+)?', sanitized)
    if not numbers:
        return None
    # Convert to float and return the max
    return float(max(numbers, key=float))

def parse_doc_intel_ingredients(
    ingredients_text: str,
    selected_model_id: str
) -> List[str]:
    """
    Parses the ingredients text into a structured list of ingredient strings.
    Each ingredient is a string like "Riso Carnaroli, 350 g".
    """
    if selected_model_id.startswith("cucina_facile"):
        # Remove the leading "ingredienti" (case-insensitive, with or without colon)
        s = re.sub(r'^\s*ingredienti[:,]?\s*', '', ingredients_text, flags=re.IGNORECASE)
        # Improved pattern: splits on capitalized words, even if not comma-separated
        # Handles: "Olio extravergine d'oliva Sale" -> ["Olio extravergine d'oliva", "Sale"]
        pattern = (
            r"([A-ZÀ-Ü][^,]*?(?: [a-zà-ü][^,]*)*)"      # Name: starts with capital, may have spaces, stops at comma or next capital
            r"(?:,\s*([^A-ZÀ-Ü]+?))?"                   # Optional: comma, then qty/unit (not starting with capital)
            r"(?=\s+[A-ZÀ-Ü]|$)"                        # Lookahead: next ingredient starts with capital or end of string
        )
        matches = re.findall(pattern, s, flags=re.VERBOSE)
        result = []
        for name, qty_unit in matches:
            name = name.strip()
            if qty_unit:
                qty_unit = qty_unit.strip()
                if qty_unit:
                    result.append(f"{name}, {qty_unit}")
                else:
                    result.append(name)
            else:
                result.append(name)
        return [x for x in result if x]
    else:
        raise NotImplementedError(f"Parsing for this model ID '{selected_model_id}' is not implemented.")


# --- Example Usage (for testing this module directly) ---
if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)

    res = parse_quantity_and_unit("1/2")
    assert res == {"value": "0.5", "unit": None}, f"Expected {'value': '0.5', 'unit': None}, but got {res}"

    # ingredient list parsing test
    ingredients_text = "ingredienti Riso Carnaroli, 350 g Speck tagliato grosso, 100 g Ricotta fresca, 60 g Gherigli di noce, 50 g Lattuga, 1 cespo Cipolla, 1 Aglio, 1 spicchio Parmigiano grattugiato Burro, 50 g Vino bianco secco, 1/2 bicchiere Brodo vegetale, 8 dl scarsi Prezzemolo, qualche foglia Olio extravergine d'oliva Sale, pepe"
    output = [
        "Riso Carnaroli, 350 g",
        "Speck tagliato grosso, 100 g",
        "Ricotta fresca, 60 g", 
        "Gherigli di noce, 50 g",
        "Lattuga, 1 cespo", 
        "Cipolla, 1", 
        "Aglio, 1 spicchio",
        "Parmigiano grattugiato", 
        "Burro, 50 g", 
        "Vino bianco secco, 1/2 bicchiere",
        "Brodo vegetale, 8 dl scarsi", 
        "Prezzemolo, qualche foglia", 
        "Olio extravergine d'oliva", 
        "Sale, pepe"
    ]
    # Test the function
    parsed_ingredients = parse_doc_intel_ingredients(ingredients_text, "cucina_facile")
    assert parsed_ingredients == output, f"Expected {output}, but got {parsed_ingredients}"


    test_ingredients = [
        "Riso Carnaroli, 350 g",
        "Speck tagliato grosso, 100 g",
        "Ricotta fresca, 60 g", 
        "Gherigli di noce, 50 g",
        "Lattuga, 1 cespo", 
        "Cipolla, 1", 
        "Aglio, 1 spicchio",
        "Parmigiano grattugiato", 
        "Burro, 50 g", 
        "Vino bianco secco, 1/2 bicchiere",
        "Brodo vegetale, 8 dl scarsi", 
        "Prezzemolo, qualche foglia", 
        "Olio extravergine d'oliva", 
        "Sale, pepe"
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
