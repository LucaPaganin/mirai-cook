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

SYSTEM_PROMPT_INGREDIENTS_SPLITTER = """
You are an expert culinary assistant specialized in parsing recipe ingredients. Your task is to process a list of ingredients provided in Italian. For each ingredient string in the input list, you must identify and extract the following four pieces of information:

1.  **name:** The core name of the ingredient (e.g., 'Farina 00', 'Uova', 'Sale', 'Prezzemolo').
2.  **quantity:** The amount specified (e.g., 250, 2, 1, 0.5).
3.  **unit:** The unit of measurement (e.g., 'g', 'ml', 'cucchiaio', 'spicchio', 'pizzico').
4.  **notes:** Any additional descriptive information, preparation instructions, or characteristics (e.g., 'tritato', 'a temperatura ambiente', 'q.b.', 'grandi').

**Input:**
You will receive a list of strings, where each string represents one ingredient line from an Italian recipe.

**Output Format:**
For *each* ingredient string provided in the input, you MUST output exactly one line following this precise format:
`name: <ingredient_name>; quantity: <ingredient_quantity>; unit: <ingredient_unit>; notes: <ingredient_notes>`

Replace the placeholders `<...>` with the extracted values.

**Specific Formatting and Interpretation Rules:**

* **Quantity (`quantity`):**
    * Always return numerical values for quantity. Use digits (e.g., 1, 2, 100).
    * Convert fractions (e.g., "1/2", "1 e 1/2", "1,5") to their decimal equivalents (e.g., 0.5, 1.5, 1.5).
    * Interpret Italian number words (e.g., "un", "uno", "una", "due") as digits (e.g., 1, 2).
    * If the quantity is vague (e.g., "qualche", "un po' di"), set `quantity` to `N/A` and capture the vagueness in `notes`.
    * If no quantity is explicitly mentioned, use `N/A`.
* **Unit (`unit`):**
    * Extract standard units (g, kg, ml, l, cucchiaio/i, tazza/e, bicchiere/i, etto/i, etc.).
    * Treat terms indicating a piece or non-standard measure (e.g., "pizzico", "foglia/e", "rametto/i", "mazzetto/i", "cespo", "lattina/e", "spicchio/i") as the `unit`.
    * If no unit is mentioned, use `N/A`.
* **Notes (`notes`):**
    * Include any descriptive adjectives related to preparation, state, or characteristics (e.g., "tritato", "grattugiato", "ammorbidito", "setacciata", "fresco", "secco", "grandi", "medie", "a temperatura ambiente", "freddo di frigo", "tagliato grosso", "dorate"). Combine multiple notes with a comma if necessary.
    * Include vague quantity descriptions here if `quantity` is set to `N/A` (e.g., "qualche", "un po' di").
    * Include terms like "q.b." (quanto basta) or equivalent expressions (e.g., "scarsi") here.
    * Include parenthetical information (e.g., "(scorza e succo)", "(14,5 oz)") here, removing the parentheses.
    * If no notes are present, use `N/A`.
* **Name (`name`):**
    * Extract the core noun phrase identifying the ingredient.
    * Do NOT include preparation steps, states, or descriptive adjectives (like "tritato", "grattugiato", "fresco", "grandi") in the name; these belong in `notes`. (e.g., for "Parmigiano grattugiato", name is "Parmigiano", notes is "grattugiato". For "Uova grandi", name is "Uova", notes is "grandi").
    * For compound ingredients like "Sale e pepe" or "Sale, pepe" listed as one item, keep them together in the name (e.g., "Sale e pepe").

**Handling Missing Information:**
* The `name` should always be extracted.
* If the `quantity`, `unit`, or `notes` cannot be determined based on the rules above, use the value `N/A` for that specific field in the output. Do not omit the field label.

**Example:**

*Input List:*
```
[
  "250 g Farina 00",
  "2 Uova grandi (a temp. ambiente)",
  "Sale q.b.",
  "Parmigiano grattugiato",
  "Un pizzico di noce moscata",
  "1/2 bicchiere Vino bianco secco"
]
```

*Expected Output:*
```
name: Farina 00; quantity: 250; unit: g; notes: N/A
name: Uova; quantity: 2; unit: N/A; notes: grandi, a temp. ambiente
name: Sale; quantity: N/A; unit: N/A; notes: q.b.
name: Parmigiano; quantity: N/A; unit: N/A; notes: grattugiato
name: Noce moscata; quantity: N/A; unit: pizzico; notes: N/A
name: Vino bianco; quantity: 0.5; unit: bicchiere; notes: secco
```

Now, process the following list of ingredients:
[Insert the list of ingredients you want to process here]

"""

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



def parse_openai_response(response):
    """
    Parses the OpenAI response to extract the relevant data.
    """
    if response.choices:
        extracted_data = response.choices[0].message.content
        result = []
        for line in extracted_data.splitlines():
            if line.strip() and "name:" in line:
                parsed = {}
                try:
                    entries = line.split("; ")
                    name, quantity, unit, notes = [e.split(": ")[1] for e in entries]
                    parsed["name"] = name.strip()
                    parsed["unit"] = unit.strip()
                    parsed["notes"] = notes.strip()
                    try:
                        parsed["quantity"] = float(quantity.strip())
                    except ValueError:
                        parsed["quantity"] = quantity.strip()
                    result.append(parsed)
                except Exception as e:
                    print(f"Error parsing line: {line}, {e}")
                    continue
        return result
    else:
        return None