# -*- coding: utf-8 -*-
"""
Azure AI Services Interaction Package for Mirai Cook.

This package contains modules for interacting with specific Azure AI services.
"""

# You can choose to expose functions directly here, e.g.:
# from .language import classify_recipe_category, extract_structured_ingredients_ner
# from .doc_intelligence import analyze_recipe_document, process_doc_intel_analyze_result
# ... etc.
# Or require users to import from the specific modules.
# -*- coding: utf-8 -*-
"""
Azure AI Services Interaction Package for Mirai Cook.

This package contains modules for interacting with specific Azure AI services.
This __init__ file exposes the primary functions from each module for easier access.
"""

# Import functions from specific service modules to make them available
# directly under the 'ai_services' namespace (e.g., ai_services.analyze_recipe_document)

# From doc_intelligence.py
try:
    from .doc_intelligence import (
        analyze_recipe_document,
        process_doc_intel_analyze_result
    )
except ImportError as e:
    print(f"Warning: Could not import from .doc_intelligence: {e}")

# From language.py
try:
    from .language import (
        classify_recipe_category,
        extract_structured_ingredients_ner_block
    )
except ImportError as e:
    print(f"Warning: Could not import from .language: {e}")

# From vision.py
try:
    from .vision import analyze_dish_image
except ImportError as e:
    print(f"Warning: Could not import from .vision: {e}")

# From speech.py
try:
    from .speech import (
        synthesize_speech,
        transcribe_audio_stream
    )
except ImportError as e:
    print(f"Warning: Could not import from .speech: {e}")

# From openai.py
try:
    from .genai import (
        generate_recipe_from_prompt,
        get_text_embedding
        # extract_recipe_from_url_ai # Uncomment when implemented
    )
except ImportError as e:
    print(f"Warning: Could not import from .genai: {e}")


# Optional: Define __all__ to control wildcard imports
# __all__ = [
#     "analyze_recipe_document",
#     "process_doc_intel_analyze_result",
#     "classify_recipe_category",
#     "extract_structured_ingredients_ner",
#     "analyze_dish_image",
#     "synthesize_speech",
#     "transcribe_audio_stream",
#     "generate_recipe_from_prompt",
#     "get_text_embedding",
# ]