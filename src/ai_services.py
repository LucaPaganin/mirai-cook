# -*- coding: utf-8 -*-
"""
Module for interacting with various Azure AI services.
Contains wrapper functions that take initialized clients and input data,
perform the AI operation, and return processed results.
"""

import logging
from typing import Optional, List, Dict, Any, Union, IO
from azure.core.exceptions import HttpResponseError, ServiceRequestError
from azure.ai.textanalytics import TextAnalyticsClient, TextDocumentInput
from azure.ai.vision.imageanalysis import ImageAnalysisClient
from azure.ai.vision.imageanalysis.models import VisualFeatures
from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.ai.documentintelligence.models import AnalyzeResult, AnalyzeDocumentRequest
from azure.cognitiveservices.speech import SpeechConfig, SpeechSynthesizer, SpeechRecognizer, ResultReason, CancellationReason, AudioDataStream
from azure.cognitiveservices.speech.audio import AudioConfig, PullAudioInputStream, PushAudioInputStream # For STT streaming
from openai import AzureOpenAI # Using the 'openai' package configured for Azure
import io # For handling byte streams

# Configure logging
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
        # Prepare the request for the SDK
        # For streams, we can pass them directly. If it's bytes, wrap in BytesIO
        doc_stream = io.BytesIO(document_stream) if isinstance(document_stream, bytes) else document_stream

        poller = doc_intel_client.begin_analyze_document(
            model_id,
            doc_stream, # Pass the stream/bytes directly
            content_type="application/octet-stream" # Assume bytes/stream input
            # Use content_type="application/pdf", "image/jpeg", etc. if passing specific types
        )
        result: AnalyzeResult = poller.result()
        logger.info(f"Document analysis completed successfully. Found {len(result.documents or [])} documents.")
        # The caller will need to parse the 'result' object based on the model used
        return result

    except HttpResponseError as e:
        logger.error(f"Document Intelligence HTTP error: {e.message}", exc_info=True)
        return None
    except ServiceRequestError as e:
         logger.error(f"Document Intelligence service request error: {e}", exc_info=True)
         return None
    except Exception as e:
        logger.error(f"Unexpected error during document analysis: {e}", exc_info=True)
        return None

# --- Language Service ---

def classify_recipe_category(
    language_client: TextAnalyticsClient,
    recipe_text: str,
    project_name: str, # Required for custom classification
    deployment_name: str # Required for custom classification
) -> Optional[Dict[str, float]]:
    """
    Classifies the recipe text into predefined categories using a custom
    single-label text classification model deployed in Azure AI Language.

    Args:
        language_client: Initialized TextAnalyticsClient.
        recipe_text: The text of the recipe (e.g., instructions + ingredients).
        project_name: The name of your custom classification project in Language Studio.
        deployment_name: The deployment name of your trained model.

    Returns:
        A dictionary containing the predicted category and its confidence score,
        or None if an error occurs or no category is confidently predicted.
        Example: {'category': 'Primo', 'confidence': 0.95}
    """
    if not language_client or not recipe_text or not project_name or not deployment_name:
        logger.error("classify_recipe_category: Missing required arguments.")
        return None

    logger.info(f"Starting recipe category classification (Project: {project_name}, Deployment: {deployment_name}).")
    try:
        documents = [recipe_text] # API expects a list of documents

        poller = language_client.begin_single_label_classify(
            documents,
            project_name=project_name,
            deployment_name=deployment_name
        )
        document_results = poller.result()

        top_category = None
        highest_confidence = 0.0

        for doc, classification_result in zip(documents, document_results):
            if classification_result.kind == "CustomSingleLabelClassification":
                classification = classification_result.classification
                logger.info(f"Predicted category for recipe text: '{classification.category}' with confidence {classification.confidence_score:.2f}")
                # Assuming single label, we take the result directly
                # You might add a confidence threshold check here
                # if classification.confidence_score > 0.7: # Example threshold
                top_category = classification.category
                highest_confidence = classification.confidence_score
                # else: logger.warning("Classification confidence below threshold.")

            elif classification_result.is_error is True:
                logger.error(f"Error classifying recipe text: {classification_result.error.message}")
                return None # Treat error as failure

        if top_category:
            return {"category": top_category, "confidence": highest_confidence}
        else:
            logger.warning("No category could be confidently determined.")
            return None

    except HttpResponseError as e:
        logger.error(f"Language Service HTTP error during classification: {e.message}", exc_info=True)
        return None
    except Exception as e:
        logger.error(f"Unexpected error during recipe classification: {e}", exc_info=True)
        return None

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
        visual_features: List of features to extract (e.g., [VisualFeatures.TAGS, VisualFeatures.CAPTION]).
                         Defaults to Tags, Caption, Objects, SmartCrops.

    Returns:
        A dictionary containing the extracted features (tags, caption, objects, smart_crops),
        or None if an error occurs.
    """
    if not vision_client or not image_data:
        logger.error("analyze_dish_image: Missing required arguments.")
        return None

    if visual_features is None:
        visual_features = [
            VisualFeatures.TAGS,
            VisualFeatures.CAPTION,
            VisualFeatures.OBJECTS,
            VisualFeatures.SMART_CROPS
        ]

    logger.info(f"Starting dish image analysis for features: {[f.name for f in visual_features]}")
    try:
        # Analyze image data (bytes or stream)
        result = vision_client.analyze(
            image_data=image_data,
            visual_features=visual_features
            # gender_neutral_caption=True # Optional parameter for captioning
        )

        analysis_output = {}
        if result.tags is not None:
            analysis_output['tags'] = [{"name": tag.name, "confidence": tag.confidence} for tag in result.tags]
            logger.info(f"Found {len(analysis_output['tags'])} tags.")
        if result.caption is not None:
            analysis_output['caption'] = {"text": result.caption.text, "confidence": result.caption.confidence}
            logger.info(f"Generated caption: '{analysis_output['caption']['text']}'")
        if result.objects is not None:
            analysis_output['objects'] = [{"name": obj.tags[0].name, "confidence": obj.tags[0].confidence, "box": obj.bounding_box} for obj in result.objects if obj.tags] # Simplification
            logger.info(f"Found {len(analysis_output['objects'])} objects.")
        if result.smart_crops is not None:
             analysis_output['smart_crops'] = [{"aspect_ratio": crop.aspect_ratio, "box": crop.bounding_box} for crop in result.smart_crops]
             logger.info(f"Found {len(analysis_output['smart_crops'])} smart crop suggestions.")

        return analysis_output if analysis_output else None

    except HttpResponseError as e:
        logger.error(f"Vision Service HTTP error during image analysis: {e.message}", exc_info=True)
        return None
    except Exception as e:
        logger.error(f"Unexpected error during image analysis: {e}", exc_info=True)
        return None

# --- Speech Service ---

def synthesize_speech(
    speech_config: SpeechConfig,
    text_to_speak: str
) -> Optional[bytes]:
    """
    Synthesizes speech from text using Azure AI Speech TTS.

    Args:
        speech_config: Initialized SpeechConfig object.
        text_to_speak: The text to convert to speech.

    Returns:
        The synthesized audio data as bytes (WAV format), or None on failure.
    """
    if not speech_config or not text_to_speak:
        logger.error("synthesize_speech: Missing required arguments.")
        return None

    logger.info(f"Starting speech synthesis for text: '{text_to_speak[:50]}...'")
    try:
        # Don't output audio to speaker directly in a web app context
        # speech_synthesizer = SpeechSynthesizer(speech_config=speech_config, audio_config=None) # Outputs to speaker
        # Instead, synthesize to memory stream
        speech_synthesizer = SpeechSynthesizer(speech_config=speech_config, audio_config=None) # Synthesize to memory by default

        result = speech_synthesizer.speak_text_async(text_to_speak).get()

        if result.reason == ResultReason.SynthesizingAudioCompleted:
            logger.info("Speech synthesis completed successfully.")
            return result.audio_data # Return the audio bytes
        elif result.reason == ResultReason.Canceled:
            cancellation_details = result.cancellation_details
            logger.error(f"Speech synthesis canceled: {cancellation_details.reason}")
            if cancellation_details.reason == CancellationReason.Error:
                logger.error(f"Error details: {cancellation_details.error_details}")
            return None
        else:
             logger.error(f"Speech synthesis failed with unexpected reason: {result.reason}")
             return None

    except Exception as e:
        logger.error(f"Unexpected error during speech synthesis: {e}", exc_info=True)
        return None

def transcribe_audio_stream(
    speech_config: SpeechConfig,
    audio_stream: Union[PullAudioInputStream, PushAudioInputStream] # Input stream from mic/webrtc
) -> Optional[str]:
    """
    Transcribes audio from a stream (e.g., microphone input via webrtc)
    using Azure AI Speech STT. Performs single utterance recognition.

    Args:
        speech_config: Initialized SpeechConfig object.
        audio_stream: An Azure Speech SDK audio input stream object.

    Returns:
        The recognized text, or None if recognition fails or is empty.
    """
    if not speech_config or not audio_stream:
        logger.error("transcribe_audio_stream: Missing required arguments.")
        return None

    logger.info("Starting audio stream transcription...")
    try:
        audio_config = AudioConfig(stream=audio_stream)
        speech_recognizer = SpeechRecognizer(speech_config=speech_config, audio_config=audio_config)

        logger.info("Speak into your microphone...") # Or indicate recording started
        result = speech_recognizer.recognize_once_async().get()

        if result.reason == ResultReason.RecognizedSpeech:
            logger.info(f"Recognized: {result.text}")
            return result.text if result.text else None
        elif result.reason == ResultReason.NoMatch:
            logger.warning("No speech could be recognized from the audio stream.")
            return None
        elif result.reason == ResultReason.Canceled:
            cancellation_details = result.cancellation_details
            logger.error(f"Speech recognition canceled: {cancellation_details.reason}")
            if cancellation_details.reason == CancellationReason.Error:
                logger.error(f"Error details: {cancellation_details.error_details}")
            return None
        else:
             logger.error(f"Speech recognition failed with unexpected reason: {result.reason}")
             return None

    except Exception as e:
        logger.error(f"Unexpected error during audio transcription: {e}", exc_info=True)
        return None

# --- OpenAI Service ---

def generate_recipe_from_prompt(
    openai_client: AzureOpenAI,
    prompt: str,
    model_deployment_name: str, # e.g., "gpt-35-turbo" deployment name
    max_tokens: int = 1000,
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
        # Using Chat Completions API (more common now)
        response = openai_client.chat.completions.create(
            model=model_deployment_name,
            messages=[
                {"role": "system", "content": "You are a helpful assistant that creates recipes."},
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


# --- TODO: Add function for URL import AI fallback ---
# def extract_recipe_from_url_ai(openai_client: AzureOpenAI, url: str) -> Optional[Dict[str, Any]]:
#     """ Extracts recipe details from URL content using OpenAI as fallback. """
#     # 1. Fetch URL content (requests/BeautifulSoup/newspaper3k)
#     # 2. Prepare prompt asking AI to extract title, ingredients, instructions from the text
#     # 3. Call OpenAI API (similar to generate_recipe_from_prompt)
#     # 4. Parse the AI response into a dictionary
#     pass

