/// An ingredient as written in the recipe, plus optional parsed fields
/// (RCP-3). The original line is always what the user sees (RCP-4).
class IngredientLine {
  const IngredientLine({
    required this.original,
    this.quantity,
    this.unit,
    this.name,
  });

  final String original;
  final double? quantity;

  /// Canonical unit symbol (see `Units`), or null for countable items.
  final String? unit;
  final String? name;

  @override
  bool operator ==(Object other) =>
      other is IngredientLine &&
      other.original == original &&
      other.quantity == quantity &&
      other.unit == unit &&
      other.name == name;

  @override
  int get hashCode => Object.hash(original, quantity, unit, name);

  @override
  String toString() => 'IngredientLine($original | $quantity $unit $name)';
}

class Recipe {
  const Recipe({
    this.id,
    required this.title,
    required this.servings,
    this.ingredients = const [],
    this.steps = const [],
    this.sourceUrl,
    this.thumbnail,
    this.tags = const [],
  });

  final int? id;
  final String title;
  final double servings;
  final List<IngredientLine> ingredients;
  final List<String> steps;
  final String? sourceUrl;
  final List<int>? thumbnail;

  /// Free-form tags (RCP-7), already cleaned with `cleanTags`.
  final List<String> tags;

  Recipe copyWith({
    int? id,
    String? title,
    double? servings,
    List<IngredientLine>? ingredients,
    List<String>? steps,
    String? sourceUrl,
    List<int>? thumbnail,
    List<String>? tags,
  }) => Recipe(
    id: id ?? this.id,
    title: title ?? this.title,
    servings: servings ?? this.servings,
    ingredients: ingredients ?? this.ingredients,
    steps: steps ?? this.steps,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    thumbnail: thumbnail ?? this.thumbnail,
    tags: tags ?? this.tags,
  );
}

/// Lightweight recipe data for lists.
class RecipeSummary {
  const RecipeSummary({required this.id, required this.title, this.thumbnail});

  final int id;
  final String title;
  final List<int>? thumbnail;
}
