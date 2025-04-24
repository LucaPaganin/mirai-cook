# -*- coding: utf-8 -*-
"""
Functions for interacting with Azure AI Document Intelligence service.
"""

import logging
import re
import io
from typing import Optional, Dict, Any, Union, IO
from azure.core.exceptions import HttpResponseError, ServiceRequestError
from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.ai.documentintelligence.models import AnalyzeResult, AnalyzeDocumentRequest

logger = logging.getLogger(__name__)

# --- Document Intelligence Service ---

def analyze_recipe_document(
    doc_intel_client: DocumentIntelligenceClient,
    model_id: str,
    document_stream: Union[bytes, IO[bytes]]
) -> Optional[AnalyzeResult]:
    """
    Analyzes a recipe document (image or PDF stream) using a specified
    Document Intelligence model (prebuilt or custom).

    Args:
        doc_intel_client: Initialized DocumentIntelligenceClient.
        model_id: The ID of the model to use (e.g., "prebuilt-read", "your-custom-model-id").
        document_stream: The document content as bytes or a file-like object.

    Returns:
        AnalyzeResult object containing the analysis results, or None if an error occurs.
    """
    if not doc_intel_client or not model_id or not document_stream:
        logger.error("analyze_recipe_document: Missing required arguments.")
        return None
    logger.info(f"Starting document analysis with model ID: {model_id}")
    try:
        doc_stream = io.BytesIO(document_stream) if isinstance(document_stream, bytes) else document_stream
        poller = doc_intel_client.begin_analyze_document(
            model_id,
            doc_stream,
            content_type="application/octet-stream"
        )
        result: AnalyzeResult = poller.result()
        logger.info(f"Document analysis completed successfully. Found {len(result.documents or [])} documents.")
        return result
    except Exception as e:
        logger.error(f"Error during document analysis: {e}", exc_info=True)
        return None

def process_doc_intel_analyze_result(
    doc_intel_fields: Optional[Dict[str, Any]], # Expecting the .fields attribute
    selected_model_id: str
) -> Dict[str, Optional[Union[str, None, int]]]:
    """
    Process the Document Intelligence analyze result fields to extract raw data.
    Extracts raw text block for ingredients, does NOT call NER here.
    Attempts basic parsing for time and difficulty.

    Args:
        doc_intel_fields (Optional[Dict[str, Any]]): The 'fields' dictionary.
        selected_model_id (str): The ID of the model used.

    Returns:
        Dict: Dictionary containing extracted raw field content.
    """
    result = {
        "title": None, "ingredients_text": None, "instructions_text": None,
        "total_time": None, "yields": None, "category": None,
        "difficulty": None, "drink": None, "calories": None
    }
    if not doc_intel_fields or not isinstance(doc_intel_fields, dict):
        logger.warning("process_doc_intel_analyze_result: Received empty or invalid fields.")
        return result

    logger.debug(f"Processing DI fields for model type starting with: {selected_model_id[:15]}")

    # --- Logic for Custom Model (Example: 'cucina_facile_v1') ---
    if selected_model_id.startswith("cucina_facile"): # Or your actual custom model prefix/ID
        logger.info("Processing result from custom 'cucina_facile' model.")
        result["title"] = doc_intel_fields.get("title", {}).get("content")
        result["ingredients_text"] = doc_intel_fields.get("ingredients", {}).get("content") # RAW TEXT BLOCK
        result["instructions_text"] = doc_intel_fields.get("description", {}).get("content")
        result["total_time"] = doc_intel_fields.get("prep_time", {}).get("content") # Raw time string
        result["yields"] = doc_intel_fields.get("yields", {}).get("content") # Raw yields string
        result["category"] = doc_intel_fields.get("category", {}).get("content")
        result["difficulty"] = doc_intel_fields.get("difficulty", {}).get("content") # Raw difficulty string
        result["drink"] = doc_intel_fields.get("wine", {}).get("content")
        result["calories"] = doc_intel_fields.get("calories", {}).get("content") # Raw calories string

        # Post-process specific fields
        if result["difficulty"]:
            try:
                difficulty_str = result["difficulty"]
                difficulty_count = difficulty_str.count("·")
                if difficulty_count > 0:
                    difficulty_map = {1: "Easy", 2: "Easy", 3: "Medium", 4: "Hard", 5: "Expert"}
                    result["difficulty"] = difficulty_map.get(difficulty_count, "Medium")
            except Exception: pass
        if result["total_time"]:
            try:
                time_num = re.findall(r'\d+', result["total_time"])
                result["total_time"] = int(time_num[0]) if time_num else None
            except Exception: result["total_time"] = None
        if result["calories"]:
             try:
                cal_num = re.findall(r'\d+', result["calories"])
                result["calories"] = int(cal_num[0]) if cal_num else None
             except Exception: result["calories"] = None

    # --- Logic for Prebuilt Models (Example: Read/Layout) ---
    elif selected_model_id in ["prebuilt-read", "prebuilt-layout"]:
        logger.warning("Processing prebuilt model results is limited within this function.")
        result["instructions_text"] = doc_intel_fields.get("content", "Could not extract content.")
        result["ingredients_text"] = ""

    else: # Fallback for unknown models
         logger.warning(f"Unknown model ID '{selected_model_id}' used for processing DI results.")
         result["instructions_text"] = doc_intel_fields.get("content", "Extraction logic not defined.")

    logger.debug(f"Processed DI Output: {result}")
    return result
