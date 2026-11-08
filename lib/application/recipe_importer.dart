import '../data/http_client.dart';
import '../data/repositories.dart';
import '../data/thumbnailer.dart';
import '../domain/ingredient_parser.dart';
import '../domain/recipe.dart';
import '../domain/recipe_extractor.dart';

sealed class ImportResult {
  const ImportResult();
}

/// An unsaved recipe to review in the editor (IMP-8).
class ImportDraft extends ImportResult {
  const ImportDraft(this.recipe, {required this.structured});

  final Recipe recipe;

  /// False when the page had no Recipe JSON-LD (IMP-5).
  final bool structured;
}

/// A recipe with this source URL already exists (IMP-9).
class ImportDuplicate extends ImportResult {
  const ImportDuplicate(this.existing, this.url);

  final Recipe existing;
  final Uri url;
}

/// The page could not be fetched (IMP-6). [url] is kept for retry.
class ImportFailure extends ImportResult {
  const ImportFailure(this.input, this.message, {this.url});

  final String input;
  final String message;
  final Uri? url;
}

/// Finds the first http(s) URL in shared or pasted text.
Uri? extractUrl(String text) {
  final m = RegExp(r'https?://[^\s<>"]+').firstMatch(text);
  if (m == null) return null;
  final raw = m.group(0)!.replaceFirst(RegExp(r'[.,;:!?)\]]+$'), '');
  final uri = Uri.tryParse(raw);
  return uri == null || uri.host.isEmpty ? null : uri;
}

class RecipeImporter {
  RecipeImporter({
    required this.http,
    required this.recipes,
    required this.thumbnailer,
    this.extractor = const RecipeExtractor(),
    this.parser = const IngredientParser(),
  });

  final HttpClient http;
  final RecipeRepository recipes;
  final Thumbnailer thumbnailer;
  final RecipeExtractor extractor;
  final IngredientParser parser;

  static const defaultServings = 4.0;

  Future<ImportResult> import(
    String input, {
    bool allowDuplicate = false,
  }) async {
    final url = extractUrl(input);
    if (url == null) {
      return ImportFailure(input, 'Nessun indirizzo web valido');
    }
    final urlText = url.toString();

    if (!allowDuplicate) {
      final existing = await recipes.findBySourceUrl(urlText);
      if (existing != null) return ImportDuplicate(existing, url);
    }

    final HttpResponse page;
    try {
      page = await http.get(url);
    } on Exception catch (e) {
      return ImportFailure(
        input,
        'Impossibile scaricare la pagina ($e)',
        url: url,
      );
    }
    if (!page.isOk) {
      return ImportFailure(
        input,
        'Impossibile scaricare la pagina (HTTP ${page.statusCode})',
        url: url,
      );
    }

    final html = page.body;
    final extracted = extractor.extract(html);
    if (extracted == null) {
      return ImportDraft(
        Recipe(
          title: extractor.pageTitle(html) ?? url.host,
          servings: defaultServings,
          sourceUrl: urlText,
        ),
        structured: false,
      );
    }

    return ImportDraft(
      Recipe(
        title: extracted.title,
        servings: extracted.servings ?? defaultServings,
        sourceUrl: urlText,
        steps: extracted.steps,
        thumbnail: await _thumbnail(url, extracted.imageUrl),
        ingredients: [
          for (final line in extracted.ingredients)
            () {
              final p = parser.parse(line); // IMP-4
              return IngredientLine(
                original: line,
                quantity: p.quantity,
                unit: p.unit,
                name: p.name,
              );
            }(),
        ],
      ),
      structured: true,
    );
  }

  Future<List<int>?> _thumbnail(Uri page, String? imageUrl) async {
    if (imageUrl == null) return null;
    try {
      final r = await http.get(page.resolve(imageUrl));
      if (!r.isOk) return null;
      return await thumbnailer.makeThumbnail(r.bodyBytes);
    } on Object {
      return null; // The image is optional.
    }
  }
}
