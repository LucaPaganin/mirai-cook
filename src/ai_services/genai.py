# -*- coding: utf-8 -*-
"""
Functions for interacting with Azure OpenAI service.
"""

import logging
from typing import Optional, List, Dict, Any
from openai import AzureOpenAI # Using the 'openai' package configured for Azure
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

    except Exception as e:
        logger.error(f"Error during OpenAI recipe generation: {e}", exc_info=True)
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
    except Exception as e:
        logger.error(f"Error during OpenAI text embedding: {e}", exc_info=True)
        return None

# --- TODO: Add function for URL import AI fallback ---
# def extract_recipe_from_url_ai(openai_client: AzureOpenAI, url: str) -> Optional[Dict[str, Any]]:
#     """ Extracts recipe details from URL content using OpenAI as fallback. """
#     pass
