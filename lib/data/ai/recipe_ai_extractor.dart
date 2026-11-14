import '../../domain/recipe_extractor.dart';

/// What the AI extractor is asked to read.
sealed class AiInput {
  const AiInput();
}

/// A public video the provider can watch directly (AI-2).
class AiVideoInput extends AiInput {
  const AiVideoInput(this.videoUrl);

  /// Canonical video URL (AI-1).
  final Uri videoUrl;
}

/// Text containing a recipe: an Instagram caption (AI-3) or text pasted by
/// the user (AI-9).
class AiTextInput extends AiInput {
  const AiTextInput(this.text);

  final String text;
}

sealed class AiExtraction {
  const AiExtraction();
}

/// A recipe found in the content (AI-4). [ExtractedRecipe.imageUrl] is
/// always null: the image comes from the platform (AI-10).
class AiRecipeFound extends AiExtraction {
  const AiRecipeFound(this.recipe);

  final ExtractedRecipe recipe;
}

/// The content was read but holds no recipe (AI-7). [title] is the video or
/// post title, if the provider reported one.
class AiNoRecipe extends AiExtraction {
  const AiNoRecipe({this.title});

  final String? title;
}

/// Why an AI request failed (AI-8).
enum AiFailureKind { notConfigured, network, invalidKey, quota, timeout, other }

class AiExtractionException implements Exception {
  const AiExtractionException(this.kind, [this.detail]);

  final AiFailureKind kind;

  /// Provider message, for diagnostics.
  final String? detail;

  @override
  String toString() =>
      'AiExtractionException(${kind.name}${detail == null ? '' : ': $detail'})';
}

/// Turns a video or a piece of text into recipe data using an AI provider.
///
/// Implementations send only the input and the extraction instructions
/// (AI-5, AI-13), and throw [AiExtractionException] on failure.
abstract interface class RecipeAiExtractor {
  /// Whether a provider key is configured (AI-12).
  Future<bool> isConfigured();

  Future<AiExtraction> extract(AiInput input);
}
