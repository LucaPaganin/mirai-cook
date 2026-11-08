import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/domain/recipe.dart';
import 'package:mirai_cook/domain/recipe_matching.dart';

void main() {
  const recipes = [
    RecipeSummary(id: 1, title: 'Lasagna alla bolognese'),
    RecipeSummary(id: 2, title: 'Caffè latte'),
    RecipeSummary(id: 3, title: 'Pesto'),
  ];

  // Covers: PLAN-19
  group('matchRecipeByTitle', () {
    for (final (text, expected) in [
      ('Lasagna alla bolognese', 1),
      ('  lasagna   ALLA bolognese ', 1),
      ('caffe latte', 2),
      ('Pesto', 3),
      ('pesto genovese', null), // no partial matches
      ('lasagna', null),
      ('', null),
    ]) {
      test('"$text" -> $expected', () {
        expect(matchRecipeByTitle(text, recipes), expected);
      });
    }
  });
}
