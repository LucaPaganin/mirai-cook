# -*- coding: utf-8 -*-
"""
Utility functions for the Mirai Cook application.
Includes functions for parsing ingredient strings (Regex),
sanitization, parsing serving information, and creating AI credentials.
Updated parse_quantity_and_unit to use UNIT_PATTERN.
"""

import re
import logging
from typing import Dict, Optional, Union, Tuple, List, Any
from unidecode import unidecode
from azure.core.credentials import AzureKeyCredential

# Configure logging
logger = logging.getLogger(__name__)

# --- Constants for Parsing ---
# Italian units only

# Peso (Weight)
COMMON_UNITS = [
    'g', 'gr', 'grammo', 'grammi',
    'etto', 'etti', 'hg', 
    'chilogrammo', 'chilogrammi', 'chilo', 'chili', 'kg',
    # Volume
    'ml', 'millilitro', 'millilitri', 
    'cl', 'centilitro', 'centilitri', 
    'dl', 'decilitro', 'decilitri',
    'l', 'lt', 'litro', 'litri',
    # Quantità (Quantity)
    'pz', 'pezzo', 'pezzi', 'confezione', 'confezioni', 'scatola', 'scatole', 'lattina', 'lattine',
    # Cucchiai (Spoons)
    'cucchiaio', 'cucchiai', 'cucchiaino', 'cucchiaini',
    # Bicchieri (Glasses)
    'bicchiere', 'bicchieri',
    # Fette, Spicchi, etc.
    'fetta', 'fette', 'spicchio', 'spicchi', 
    'rametto', 'rametti', 'mazzetto', 'mazzetti', 'gambo', 'gambi', 'cespo', 'cespi',
    # Altro (Other)
    'pizzico', 'qb', 'q.b', 'q.b.', 'busta', 'buste', 'foglia', 'foglie'
]

# Build a regex pattern for units (case-insensitive matching handled by flag)
UNIT_PATTERN = r'(?:' + '|'.join(re.escape(unit) for unit in COMMON_UNITS) + r')\.?'

# Regex pattern for numbers, including fractions and decimals
NUMBER_PATTERN = r'(\d+\s*\/\s*\d+|\d+\s+\d+\s*\/\s*\d+|\d*\.\d+|\d+)'

# --- Parsing Helper Functions ---

def _parse_quantity(qty_str: str) -> Optional[float]:
    """Helper function to parse quantity strings into floats."""
    qty_str = qty_str.strip().replace(',', '.') # Handle comma decimal separator
    try:
        if '/' not in qty_str: return float(qty_str)
        if ' ' in qty_str: # Mixed fraction "1 1/2"
            parts = qty_str.split(' ', 1)
            whole = int(parts[0])
            num, den = map(int, parts[1].split('/'))
            if den == 0: return None
            return whole + (num / den)
        else: # Simple fraction "1/2"
            num, den = map(int, qty_str.split('/'))
            if den == 0: return None
            return num / den
    except (ValueError, ZeroDivisionError, IndexError) as e:
        logger.debug(f"Could not parse quantity string: '{qty_str}', Error: {e}")
        return None

# --- UPDATED FUNCTION ---
def parse_quantity_and_unit(text_to_parse: str) -> Tuple[Optional[float], Optional[str]]:
    """
    Tries to split a text fragment into number and known unit using regex patterns.

    Handles cases like "100 g", "1/2 cup", "2", "qb".

    Args:
        text_to_parse (str): The text potentially containing quantity and unit.

    Returns:
        Tuple[Optional[float], Optional[str]]: The parsed quantity and unit, or None.
    """
    text = text_to_parse.strip()
    text_lower = text.lower()
    quantity = None
    unit = None

    # 1. Handle q.b. explicitly
    if text_lower in ['qb', 'q.b', 'q.b.']:
        logger.debug(f"Parsed '{text_to_parse}' as unit 'qb'")
        return None, 'qb'

    # 2. Handle potential fractions (check if the whole string is a fraction)
    # Use _parse_quantity which already handles fractions
    parsed_as_number = _parse_quantity(text)
    if parsed_as_number is not None and '/' in text:
        logger.debug(f"Parsed '{text_to_parse}' as quantity {parsed_as_number} (fraction), no unit.")
        return parsed_as_number, None

    # 3. Try matching Number followed by optional known Unit at the end
    # Use named groups for clarity. Unit group is optional.
    pattern = rf'^\s*(?P<value>{NUMBER_PATTERN})\s*(?P<unit>{UNIT_PATTERN})?\s*$'
    match = re.match(pattern, text, flags=re.IGNORECASE)

    if match:
        quantity_str = match.group("value")
        unit_str = match.group("unit") # This will be None if the optional group doesn't match

        quantity = _parse_quantity(quantity_str) # Parse the number part

        if unit_str:
            unit = unit_str.strip().rstrip('.').lower()
            if unit == 'q.b.': unit = 'qb' # Standardize q.b.
            logger.debug(f"Parsed '{text_to_parse}' as quantity {quantity}, unit '{unit}'")
            return quantity, unit
        else:
            # Matched a number but no known unit followed
            logger.debug(f"Parsed '{text_to_parse}' as quantity {quantity}, no recognized unit.")
            return quantity, None

    # 4. Fallback: Check if the whole string is just a known unit
    # Use fullmatch to ensure the entire string is the unit
    if re.fullmatch(UNIT_PATTERN, text, flags=re.IGNORECASE):
         unit = text.strip().rstrip('.').lower()
         if unit == 'q.b.': unit = 'qb'
         logger.debug(f"Parsed '{text_to_parse}' as unit '{unit}', no quantity.")
         return None, unit

    # 5. Fallback: Check if the whole string is just a number (already covered by step 2/3 if valid)
    # If parsed_as_number is not None here, it means it's a number without a unit
    if parsed_as_number is not None:
        logger.debug(f"Parsed '{text_to_parse}' as quantity {parsed_as_number}, no unit (fallback).")
        return parsed_as_number, None

    # 6. If nothing matches, return None for both
    logger.debug(f"Could not parse quantity/unit from: '{text_to_parse}'")
    return None, None
# --- END UPDATED FUNCTION ---


# --- Regex Parsing Function (Still available as fallback/alternative) ---
def parse_ingredient_string(line: str) -> Dict[str, Optional[Union[float, str]]]:
    """
    Attempts to parse a single ingredient line into quantity, unit, and name
    using regular expressions for common patterns.
    """
    # ... (Implementation remains the same as before) ...
    original_line = line.strip(); logger.debug(f"Parsing ingredient line via Regex: '{original_line}'")
    parsed = {"quantity": None, "unit": None, "name": None, "notes": None, "original": original_line}
    if not original_line: return parsed
    notes_match = re.search(r'\((.*?)\)', line)
    if notes_match: parsed["notes"] = notes_match.group(1).strip(); line = re.sub(r'\(.*?\)', '', line).strip()
    else: line = original_line.strip()
    line_parts = re.split(r'\s*[,-]\s*', line, 1); line = line_parts[0].strip()
    if len(line_parts) > 1 and parsed["notes"] is None: parsed["notes"] = line_parts[1].strip()
    def _process_match(match_obj, parsed_dict, keys_map):
        for key_model, key_regex in keys_map.items():
            try:
                value = match_obj.group(key_regex)
                if value is not None:
                     if key_model == 'quantity': value = _parse_quantity(value)
                     elif key_model == 'unit': value = value.strip().rstrip('.').lower(); value = 'qb' if value == 'q.b.' else value
                     elif key_model == 'name' or key_model == 'notes': value = value.strip()
                     parsed_dict[key_model] = value
            except (IndexError, AttributeError): pass
        return parsed_dict
    patterns = [
        {"name": "Number Unit Name", "regex": rf'^\s*(?P<quantity>{NUMBER_PATTERN})\s*(?P<unit>{UNIT_PATTERN})\s+(?P<name>.*)$', "flags": re.IGNORECASE, "map": {"quantity": "quantity", "unit": "unit", "name": "name"}},
        {"name": "Number Name", "regex": rf'^\s*(?P<quantity>{NUMBER_PATTERN})\s+(?P<name>[^\d].*)$', "flags": 0, "map": {"quantity": "quantity", "name": "name"}},
        {"name": "Name Number [Unit] [Notes]", "regex": rf'^(?P<name>.*?)\s+(?P<quantity>{NUMBER_PATTERN})\s*(?P<unit>{UNIT_PATTERN})?\s*(?P<notes>.*)$', "flags": re.IGNORECASE, "map": {"name": "name", "quantity": "quantity", "unit": "unit", "notes": "notes"}},
        {"name": "Name Number", "regex": rf'^(?P<name>.*?)\s+(?P<quantity>{NUMBER_PATTERN})\s*$', "flags": 0, "map": {"name": "name", "quantity": "quantity"}},
        {"name": "Unit Name", "regex": rf'^\s*(?P<unit>{UNIT_PATTERN})\s+(?:of\s+)?(?P<name>.*)$', "flags": re.IGNORECASE, "map": {"unit": "unit", "name": "name"}}
    ]
    for pat in patterns:
        match = re.match(pat["regex"], line, flags=pat["flags"])
        if match:
            potential_name = match.groupdict().get("name")
            if pat["name"].startswith("Name") and potential_name and potential_name.lower() in COMMON_UNITS: logger.debug(f"Pattern '{pat['name']}' potential name matched a common unit, skipping."); continue
            logger.debug(f"Matched Pattern: {pat['name']}")
            parsed = _process_match(match, parsed, pat["map"])
            if pat["name"] == "Name Number [Unit] [Notes]" and parsed.get("notes"):
                if parsed.get("notes") and notes_match and parsed["notes"] != notes_match.group(1).strip(): parsed["notes"] = f"{notes_match.group(1).strip()}, {parsed['notes']}"
                elif notes_match: parsed["notes"] = notes_match.group(1).strip()
            elif parsed["notes"] is None and notes_match: parsed["notes"] = notes_match.group(1).strip()
            return parsed
    logger.debug(f"No specific pattern matched for '{line}'. Assigning full string to name.")
    parsed["name"] = line
    if parsed["notes"] is None and notes_match: parsed["notes"] = notes_match.group(1).strip()
    return parsed


# --- Sanitization and Servings Parsers (Unchanged) ---
def sanitize_for_id(name: str) -> str:
    """Creates a readable ID from a name using unidecode."""
    if not name: logger.warning("Attempting to sanitize an empty name, generating UUID."); return f"ingredient_{uuid.uuid4()}"
    try: s = unidecode(name)
    except Exception as e: logger.error(f"Error applying unidecode to name '{name}': {e}. Proceeding without unidecode."); s = name
    s = s.lower(); s = re.sub(r'\s+', '_', s); s = re.sub(r'[^\w_]+', '', s); s = re.sub(r'_+', '_', s).strip('_')
    if not s: logger.warning(f"Name '{name}' resulted empty after sanitization, generating UUID."); return f"ingredient_{uuid.uuid4()}"
    return s

def _normalize_name_for_search(name: str) -> str:
    """Normalizes a name for searching/comparison."""
    if not name: return ""
    return " ".join(name.lower().split())

def parse_servings(yields_string: Optional[str]) -> Optional[int]:
    """Extracts the first integer number found in a yields/servings string."""
    if not yields_string: return None
    numbers = re.findall(r'\d+', yields_string)
    if numbers:
        try: return int(numbers[0])
        except ValueError: logger.warning(f"Could not convert found number to integer in yields string: '{yields_string}'"); return None
    else: logger.debug(f"No number found in yields string: '{yields_string}'"); return None

# --- Credential Helper ---
def get_ai_services_credential(secrets: Dict[str, Optional[str]], service_key_name: str) -> Optional[AzureKeyCredential]:
     """Creates an AzureKeyCredential using a specific service key name retrieved from secrets."""
     key = secrets.get(service_key_name)
     if not key: logger.error(f"AI Service key '{service_key_name}' not found in secrets."); return None
     logger.debug(f"Created AzureKeyCredential for service key: {service_key_name}")
     return AzureKeyCredential(key)


# --- Example Usage ---
if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    print("--- Testing Regex Ingredient Parser ---")
    test_ingredients_regex = ["2 cups flour, sifted", "100g butter", "Eggs 2 large"]
    for item in test_ingredients_regex: print(f"\nOriginal: '{item}'\nParsed (Regex): {parse_ingredient_string(item)}")
    print("\n--- Testing Servings Parser ---")
    test_yields = ["Serves 4", "Makes 6-8 servings"]
    for item in test_yields: print(f"Original: '{item}' -> Parsed Servings: {parse_servings(item)}")
    print("\n--- Testing Qty/Unit Parser ---")
    test_qty_units = ["100 g", "1/2 cup", "2", "1 1/2 tsp", "qb", "1.5kg", "1,5 kg", "1/2", "1 / 2", "1 1 / 2"]
    for item in test_qty_units: print(f"Original: '{item}' -> Parsed Qty/Unit: {parse_quantity_and_unit(item)}")

