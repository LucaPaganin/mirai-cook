import 'name_normalizer.dart';
import 'recipe.dart';

/// Id of the recipe whose title equals [text] after normalization (case,
/// accents, spacing), or null. Partial matches are not linked (PLAN-19).
int? matchRecipeByTitle(String text, Iterable<RecipeSummary> recipes) {
  final key = normalizeName(text);
  if (key.isEmpty) return null;
  for (final r in recipes) {
    if (normalizeName(r.title) == key) return r.id;
  }
  return null;
}
