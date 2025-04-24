# -*- coding: utf-8 -*-
"""
Functions for interacting with Azure AI Vision service.
"""

import logging
from typing import Optional, List, Dict, Any, Union, IO
from azure.core.exceptions import HttpResponseError
from azure.ai.vision.imageanalysis import ImageAnalysisClient
from azure.ai.vision.imageanalysis.models import VisualFeatures

logger = logging.getLogger(__name__)

# --- Vision Service ---
def analyze_dish_image(
    vision_client: ImageAnalysisClient,
    image_data: Union[bytes, IO[bytes]],
    visual_features: Optional[List[VisualFeatures]] = None
) -> Optional[Dict[str, Any]]:
    """
    Analyzes an image of a finished dish using Azure AI Vision.

    Args:
        vision_client: Initialized ImageAnalysisClient.
        image_data: The image content as bytes or a file-like object.
        visual_features: List of features to extract. Defaults to common ones.

    Returns:
        A dictionary containing the extracted features, or None if an error occurs.
    """
    if not vision_client or not image_data:
        logger.error("analyze_dish_image: Missing required arguments.")
        return None

    if visual_features is None:
        visual_features = [
            VisualFeatures.TAGS, VisualFeatures.CAPTION,
            VisualFeatures.OBJECTS, VisualFeatures.SMART_CROPS
        ]

    logger.info(f"Starting dish image analysis for features: {[f.name for f in visual_features]}")
    try:
        result = vision_client.analyze(
            image_data=image_data,
            visual_features=visual_features
        )

        analysis_output = {}
        if result.tags is not None:
            analysis_output['tags'] = [{"name": tag.name, "confidence": tag.confidence} for tag in result.tags]
            logger.info(f"Found {len(analysis_output['tags'])} tags.")
        if result.caption is not None:
            analysis_output['caption'] = {"text": result.caption.text, "confidence": result.caption.confidence}
            logger.info(f"Generated caption: '{analysis_output['caption']['text']}'")
        if result.objects is not None:
            analysis_output['objects'] = [{"name": obj.tags[0].name, "confidence": obj.tags[0].confidence, "box": obj.bounding_box} for obj in result.objects if obj.tags]
            logger.info(f"Found {len(analysis_output['objects'])} objects.")
        if result.smart_crops is not None:
             analysis_output['smart_crops'] = [{"aspect_ratio": crop.aspect_ratio, "box": crop.bounding_box} for crop in result.smart_crops]
             logger.info(f"Found {len(analysis_output['smart_crops'])} smart crop suggestions.")

        return analysis_output if analysis_output else None

    except Exception as e:
        logger.error(f"Error during image analysis: {e}", exc_info=True)
        return None
