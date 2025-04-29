# -*- coding: utf-8 -*-
"""
Contains the RecipeImporter class responsible for fetching recipe data
from various sources (URL, Document) and performing initial structuring.
"""

import logging
from typing import Optional, List, Dict, Any, Union, IO
# Import necessary Pydantic models
try:
    from .models import Recipe, IngredientItem # Might not need full models here yet
    from .utils import parse_servings, parse_quantity_and_unit # If needed for post-processing scraped data
except ImportError:
    from models import Recipe, IngredientItem
    from utils import parse_servings, parse_quantity_and_unit
    logging.warning("Could not perform relative import for models/utils in importers.py.")

# Import scraping and AI functions
try:
    from .recipe_scraping import scrape_recipe_metadata
    from .ai_services.doc_intelligence import analyze_recipe_document, process_doc_intel_analyze_result
    from .ai_services.genai import parse_ingredient_block_openai, parse_ingredient_list_openai # Use OpenAI parser
except ImportError as e:
     logging.error(f"Failed to import necessary functions for RecipeImporter: {e}")
     # Depending on how critical these are, you might raise the error
     # raise e

# Import Azure client types for type hinting
from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.cosmos import ContainerProxy
from openai import AzureOpenAI
import os # For environment variables

logger = logging.getLogger(__name__)

class RecipeImporter:
    """
    Handles importing recipe data from various sources and performs
    initial parsing and structuring into a dictionary format suitable
    for pre-populating the Add/Edit page.
    """

    def __init__(self,
                 doc_intel_client: DocumentIntelligenceClient,
                 openai_client: AzureOpenAI,
                 ingredients_container: ContainerProxy,
                 # Add other clients if needed for future methods (e.g., TheMealDB client)
                 ):
        """
        Initializes the importer with necessary Azure clients.
        """
        if not doc_intel_client: 
            logger.warning("Document Intelligence client not provided to RecipeImporter.")
        if not openai_client: 
            logger.warning("OpenAI client not provided to RecipeImporter.")

        self.doc_intel_client = doc_intel_client
        self.openai_client = openai_client
        # Get model names from environment variables or config
        self.openai_parser_model = os.getenv("AZURE_OPENAI_PARSER_DEPLOYMENT", "gpt-4o-mini") # Model for parsing ingredients

    def _parse_ingredients_with_ai(self, ingredients_input: Union[List[str], str]) -> List[Dict[str, Any]]:
        """
        Internal helper to parse ingredients using the appropriate OpenAI function.
        Returns a list of parsed ingredient dictionaries.
        """
        if not self.openai_client:
            logger.error("OpenAI client is not available for ingredient parsing.")
            return []

        parsed_ingredients = []
        if isinstance(ingredients_input, list): # List of strings (from scraper)
            if ingredients_input:
                parsed_ingredients = parse_ingredient_list_openai(
                    self.openai_client,
                    ingredients_input,
                    self.openai_parser_model
                )
        elif isinstance(ingredients_input, str): # Text block (from DI)
            if ingredients_input.strip():
                parsed_ingredients = parse_ingredient_block_openai(
                    self.openai_client,
                    ingredients_input,
                    self.openai_parser_model
                )

        return parsed_ingredients if parsed_ingredients else [] # Return empty list if parsing fails


    def import_from_url(self, url: str) -> Optional[Dict[str, Any]]:
        """
        Imports a recipe from a URL using recipe-scrapers and then
        parses the ingredients using OpenAI.

        Args:
            url (str): The URL of the recipe page.

        Returns:
            Optional[Dict[str, Any]]: A dictionary containing structured recipe data
                                      ready for verification, or None on failure.
                                      Includes 'parsed_ingredients' key.
        """
        logger.info(f"Attempting import from URL: {url}")
        scraped_data = scrape_recipe_metadata(url)
        if not scraped_data:
            # TODO: Implement AI fallback for scraping the *whole page* if desired
            logger.error(f"Failed to scrape recipe from URL: {url}")
            return None

        logger.info("Scraping successful. Now parsing ingredients with AI...")
        # Prepare data structure - pass raw ingredient list/text to helper
        extracted_data = {
            "title": scraped_data.get("title"),
            "ingredients": scraped_data.get("ingredients", []), # Pass raw list from scraper
            "instructions_text": scraped_data.get("instructions_text"),
            "image_url": scraped_data.get("image"),
            "source_url": url,
            "source_type": "Imported (URL Scraper)",
            "yields": scraped_data.get("yields"),
            "total_time": scraped_data.get("total_time"),
            "category": scraped_data.get("category"),
            "difficulty": scraped_data.get("difficulty"),
            "calories": scraped_data.get("calories")
        }

        # Parse ingredients using AI
        parsed_ingredients = self._parse_ingredients_with_ai(extracted_data["ingredients"])
        extracted_data["parsed_ingredients"] = parsed_ingredients # Add parsed list

        # Basic validation after parsing
        if not extracted_data.get('title') or not extracted_data.get('instructions_text'):
             logger.warning(f"Essential fields (title/instructions) missing after scraping/parsing {url}.")
             # Still return data for user review, but log warning
             # return None

        logger.info(f"Successfully processed URL import for: {extracted_data.get('title')}")
        return extracted_data


    def import_from_document(self, document_stream: Union[bytes, IO[bytes]], model_id: str) -> Optional[Dict[str, Any]]:
        """
        Imports a recipe by analyzing a document stream using Document Intelligence,
        then parses the extracted ingredients using OpenAI.

        Args:
            document_stream: The document content as bytes or a file-like object.
            model_id: The Document Intelligence model ID to use.

        Returns:
            Optional[Dict[str, Any]]: A dictionary containing structured recipe data
                                      ready for verification, or None on failure.
                                      Includes 'parsed_ingredients' key.
        """
        if not self.doc_intel_client:
            logger.error("Document Intelligence client not initialized in RecipeImporter.")
            return None

        logger.info(f"Attempting import from document using DI model: {model_id}")
        analyze_result = analyze_recipe_document(self.doc_intel_client, model_id, document_stream)

        if not analyze_result or not analyze_result.documents:
            logger.error("Document Intelligence analysis failed or returned no documents.")
            return None

        # Process the fields extracted by Document Intelligence
        extracted_fields = process_doc_intel_analyze_result(
            analyze_result.documents[0].fields, # Pass fields of first document
            model_id
        )
        if not extracted_fields or not extracted_fields.get('title'):
             logger.error("Failed to extract essential fields from DI result.")
             return None

        logger.info("Document Intelligence extraction successful. Now parsing ingredients with AI...")
        # Prepare data structure - pass raw ingredient text block to helper
        final_extracted_data = {
            "title": extracted_fields.get('title'),
            "ingredients_text": extracted_fields.get('ingredients_text'), # Pass raw text block
            "instructions_text": extracted_fields.get('instructions_text'),
            "total_time": extracted_fields.get('total_time'),
            "yields": extracted_fields.get('yields'),
            "difficulty": extracted_fields.get('difficulty'),
            "source_type": "Digitalizzata",
            "image_url": None, # No image from document analysis
            "drink": extracted_fields.get('drink'),
            "category": extracted_fields.get('category'),
            "calories": extracted_fields.get('calories')
        }

        # Parse ingredients using AI
        parsed_ingredients = self._parse_ingredients_with_ai(final_extracted_data["ingredients_text"])
        final_extracted_data["parsed_ingredients"] = parsed_ingredients # Add parsed list

        logger.info(f"Successfully processed document import for: {final_extracted_data.get('title')}")
        return final_extracted_data

    # --- TODO: Add import_from_themealdb method ---

