import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/data/db/drift_repositories.dart';
import 'package:mirai_cook/domain/recipe.dart';

import 'helpers.dart';

Future<void> openRecipesTab(WidgetTester tester) async {
  await tester.tap(find.text('Ricette'));
  await settle(tester);
}

void main() {
  // Covers: RCP-1
  appTest(
    'recipe book lists and searches by title',
    seed: (db) async {
      final r = DriftRecipeRepository(db);
      await r.save(const Recipe(title: 'Pasta al pesto', servings: 2));
      await r.save(const Recipe(title: 'Zuppa di farro', servings: 4));
    },
    (tester, app) async {
      await openRecipesTab(tester);
      expect(find.text('Pasta al pesto'), findsOneWidget);
      expect(find.text('Zuppa di farro'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('recipe-search')), 'zup');
      await settle(tester);
      expect(find.text('Pasta al pesto'), findsNothing);
      expect(find.text('Zuppa di farro'), findsOneWidget);
    },
  );

  // Covers: RCP-3, RCP-4, RCP-5
  appTest('creating a recipe parses ingredients and shows original lines', (
    tester,
    app,
  ) async {
    await openRecipesTab(tester);
    await tester.tap(find.byTooltip('Nuova ricetta'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('recipe-title')), 'Frittata');
    await tester.enterText(find.byKey(const Key('recipe-servings')), '2');
    await tester.enterText(
      find.byKey(const Key('recipe-ingredients')),
      '4 uova\n50 g di parmigiano\nSale q.b.',
    );
    await tester.tap(find.byKey(const Key('save-recipe')));
    await settle(tester);

    final saved = (await tester.runAsync(
      () => DriftRecipeRepository(app.db).watchAll().first,
    ))!;
    final recipe = (await tester.runAsync(
      () => DriftRecipeRepository(app.db).get(saved.single.id),
    ))!;
    expect(recipe.ingredients, const [
      IngredientLine(original: '4 uova', quantity: 4, name: 'uova'),
      IngredientLine(
        original: '50 g di parmigiano',
        quantity: 50,
        unit: 'g',
        name: 'parmigiano',
      ),
      IngredientLine(original: 'Sale q.b.', name: 'Sale'),
    ]);

    await tester.tap(find.text('Frittata'));
    await settle(tester);
    expect(find.text('• 50 g di parmigiano'), findsOneWidget);
  });

  // Covers: RCP-5
  appTest('the editor refuses an empty title', (tester, app) async {
    await openRecipesTab(tester);
    await tester.tap(find.byTooltip('Nuova ricetta'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('save-recipe')));
    await settle(tester);
    expect(find.text('Inserisci un titolo'), findsOneWidget);
  });
}
