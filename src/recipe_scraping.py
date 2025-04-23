# -*- coding: utf-8 -*-
"""
Utility functions for scraping recipe data from URLs.
Primarily uses the 'recipe-scrapers' library.
"""

import logging
from recipe_scrapers import scrape_me
from recipe_scrapers import WebsiteNotImplementedError, NoSchemaFoundInWildMode
from typing import Dict, Optional, List, Any

# Configure logging
logger = logging.getLogger(__name__)

def scrape_recipe_metadata(url: str) -> Optional[Dict[str, Any]]:
    """
    Attempts to scrape recipe data from a given URL using the recipe-scrapers library.

    Args:
        url (str): The URL of the recipe page.

    Returns:
        Optional[Dict[str, Any]]: A dictionary containing extracted recipe data
                                  (e.g., title, total_time, yields, ingredients, instructions, image)
                                  if successful, otherwise None.
                                  Ingredients are typically returned as a list of strings.
                                  Instructions are typically returned as a single string or list of strings.
    """
    if not url:
        logger.warning("scrape_recipe_metadata called with empty URL.")
        return None

    logger.info(f"Attempting to scrape recipe metadata from: {url}")
    scraped_data = {}
    try:
        scraper = scrape_me(url)

        # Extract common fields (check documentation for all available fields)
        scraped_data['title'] = scraper.title()
        scraped_data['total_time'] = scraper.total_time() # Often in minutes
        scraped_data['yields'] = scraper.yields() # e.g., "4 servings"
        scraped_data['ingredients'] = scraper.ingredients() # List[str]
        scraped_data['instructions_list'] = scraper.instructions_list() # List[str]
        # Fallback if instructions_list is empty
        if not scraped_data['instructions_list']:
             scraped_data['instructions_text'] = scraper.instructions() # Single string with newlines
        else:
             scraped_data['instructions_text'] = "\n".join(scraped_data['instructions_list'])

        scraped_data['image'] = scraper.image() # URL of the main image
        scraped_data['nutrients'] = scraper.nutrients() # Dictionary, often incomplete or absent
        scraped_data['canonical_url'] = scraper.canonical_url()
        scraped_data['host'] = scraper.host()

        # Basic validation: Check if essential fields were extracted
        if not scraped_data.get('title') or not (scraped_data.get('ingredients') or scraped_data.get('instructions_text')):
             logger.warning(f"Essential fields (title, ingredients/instructions) missing after scraping {url}. Treating as failure.")
             return None

        logger.info(f"Successfully scraped data for '{scraped_data.get('title')}' from {url}")
        return scraped_data

    except WebsiteNotImplementedError:
        logger.warning(f"Website not explicitly supported by recipe-scrapers (or wild mode failed): {url}")
        return None
    except NoSchemaFoundInWildMode:
         logger.warning(f"Wild mode could not find recipe schema on: {url}")
         return None
    except Exception as e:
        # Catch other potential errors (network issues, parsing errors, etc.)
        logger.error(f"Unexpected error scraping {url}: {e}", exc_info=True)
        return None

# Example usage (for testing this module directly)
if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    # Test URL (replace with a real one, e.g., from Giallo Zafferano)
    # test_url = "https://www.giallozafferano.it/ricette/Spaghetti-aglio-olio-e-peperoncino.html"
    test_url = input("Enter a recipe URL to test scraping: ")
    if test_url:
        data = scrape_recipe_metadata(test_url)
        if data:
            print("\n--- Scraped Data ---")
            print(f"Title: {data.get('title')}")
            print(f"Yields: {data.get('yields')}")
            print(f"Total Time: {data.get('total_time')}")
            print(f"Image URL: {data.get('image')}")
            print("\nIngredients:")
            for ingredient in data.get('ingredients', []):
                print(f"- {ingredient}")
            print("\nInstructions:")
            # Prefer list if available
            if data.get('instructions_list'):
                 for i, step in enumerate(data.get('instructions_list', [])):
                      print(f"{i+1}. {step}")
            else:
                 print(data.get('instructions_text'))
            # print(f"\nNutrients: {data.get('nutrients')}") # Often empty/unreliable
        else:
            print(f"\nCould not scrape recipe data from the URL.")

