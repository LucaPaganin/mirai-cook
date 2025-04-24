# -*- coding: utf-8 -*-
"""
Functions for interacting with Azure AI Speech service (TTS/STT).
"""

import logging
from typing import Optional, Union
from azure.cognitiveservices.speech import SpeechConfig, SpeechSynthesizer, SpeechRecognizer, ResultReason, CancellationReason
from azure.cognitiveservices.speech.audio import AudioConfig, PullAudioInputStream, PushAudioInputStream

logger = logging.getLogger(__name__)

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
        # Synthesize to memory stream
        speech_synthesizer = SpeechSynthesizer(speech_config=speech_config, audio_config=None)
        result = speech_synthesizer.speak_text_async(text_to_speak).get()

        if result.reason == ResultReason.SynthesizingAudioCompleted:
            logger.info("Speech synthesis completed successfully.")
            return result.audio_data
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
    audio_stream: Union[PullAudioInputStream, PushAudioInputStream]
) -> Optional[str]:
    """
    Transcribes audio from a stream using Azure AI Speech STT (single utterance).

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
        logger.info("Attempting single utterance recognition...")
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
