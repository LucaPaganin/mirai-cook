import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/data/db/drift_repositories.dart';
import 'package:mirai_cook/domain/calendar.dart';
import 'package:mirai_cook/domain/meal.dart';
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

  // Covers: PLAN-20
  appTest(
    'saving a recipe links meals planned with its title',
    seed: (db) => DriftPlanRepository(db).addItem(
      SlotId(const CalendarDate(2026, 11, 5), MealType.dinner),
      const FreeTextItem('frittata'),
    ),
    (tester, app) async {
      await openRecipesTab(tester);
      await tester.tap(find.byTooltip('Nuova ricetta'));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('recipe-title')), 'Frittata');
      await tester.tap(find.byKey(const Key('save-recipe')));
      await settle(tester);
      const thu = CalendarDate(2026, 11, 5);
      final slots = (await tester.runAsync(
        () => DriftPlanRepository(app.db).getRange(thu, thu),
      ))!;
      expect(slots[SlotId(thu, MealType.dinner)]!.single, isA<RecipeItem>());
    },
  );

  // Covers: RCP-7, RCP-8
  appTest(
    'tags are added in the editor with suggestions from existing ones',
    seed: (db) =>
        DriftRecipeRepository(db)
            .save(const Recipe(title: 'Pesto', servings: 2, tags: ['Veloce'])),
    (tester, app) async {
      await openRecipesTab(tester);
      await tester.tap(find.byTooltip('Nuova ricetta'));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('recipe-title')), 'Pizza');
      await tester.enterText(find.byKey(const Key('tag-field')), 've');
      await settle(tester);
      await tester.tap(find.byKey(const Key('tag-suggestion-Veloce')));
      await settle(tester);
      expect(find.byKey(const Key('tag-chip-Veloce')), findsOneWidget);
      // A typed, unconfirmed tag is saved too.
      await tester.enterText(find.byKey(const Key('tag-field')), 'forno');
      await tester.tap(find.byKey(const Key('save-recipe')));
      await settle(tester);
      final list = (await tester.runAsync(
        () => DriftRecipeRepository(app.db).watchAll(query: 'pizza').first,
      ))!;
      final pizza = (await tester.runAsync(
        () => DriftRecipeRepository(app.db).get(list.single.id),
      ))!;
      expect(pizza.tags, ['forno', 'Veloce']);
    },
  );

  // Covers: RCP-9
  appTest(
    'tag filters narrow the recipe book',
    seed: (db) async {
      final r = DriftRecipeRepository(db);
      await r.save(
        const Recipe(title: 'Pasta', servings: 2, tags: ['Veloce', 'Primi']),
      );
      await r.save(
        const Recipe(title: 'Arrosto', servings: 4, tags: ['Forno']),
      );
    },
    (tester, app) async {
      await openRecipesTab(tester);
      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('Arrosto'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tag-filter-Forno')));
      await settle(tester);
      expect(find.text('Pasta'), findsNothing);
      expect(find.text('Arrosto'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tag-filter-Veloce')));
      await settle(tester);
      expect(find.text('Nessun risultato'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tag-filter-Forno')));
      await settle(tester);
      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('Arrosto'), findsNothing);
    },
  );
}
