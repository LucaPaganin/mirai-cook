import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/data/db/app_database.dart';
import 'package:mirai_cook/data/db/drift_repositories.dart';
import 'package:mirai_cook/domain/calendar.dart';
import 'package:mirai_cook/domain/meal.dart';
import 'package:mirai_cook/domain/recipe.dart';

import 'helpers.dart';

const thu = CalendarDate(2026, 11, 5);

Future<void> seedWeek(AppDatabase db) async {
  final recipes = DriftRecipeRepository(db);
  final plan = DriftPlanRepository(db);
  final id = await recipes.save(
    const Recipe(
      title: 'Torta',
      servings: 4,
      ingredients: [
        IngredientLine(
          original: '200 g farina',
          quantity: 200,
          unit: 'g',
          name: 'farina',
        ),
        IngredientLine(original: '2 uova', quantity: 2, name: 'uova'),
        IngredientLine(original: 'Sale q.b.', name: 'Sale'),
      ],
    ),
  );
  await plan.addItem(
    SlotId(thu, MealType.dinner),
    RecipeItem(recipeId: id, servings: 4),
  );
  await plan.addItem(
    SlotId(thu.addDays(1), MealType.dinner),
    RecipeItem(recipeId: id, servings: 2),
  );
  await plan.addItem(SlotId(thu, MealType.lunch), const FreeTextItem('Pizza'));
}

Future<void> openShopping(WidgetTester tester) async {
  await tester.tap(find.text('Spesa'));
  await settle(tester);
}

void main() {
  // Covers: SHOP-1, SHOP-2, SHOP-4, SHOP-9, SHOP-13
  appTest(
    'lists scaled, merged ingredients grouped by section',
    seed: seedWeek,
    (tester, app) async {
      await openShopping(tester);
      expect(find.text('Dispensa'), findsOneWidget);
      expect(find.text('Latticini e uova'), findsOneWidget);
      expect(find.text('farina'), findsOneWidget);
      expect(find.text('300 g'), findsOneWidget); // 200 + 100
      expect(find.text('uova'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Sale q.b.'), findsOneWidget);
      expect(find.text('Pizza'), findsNothing);
    },
  );

  // Covers: SHOP-5, SHOP-6
  appTest('manual items can be added and items checked', seed: seedWeek, (
    tester,
    app,
  ) async {
    await openShopping(tester);
    await tester.enterText(
      find.byKey(const Key('manual-item-field')),
      'Detersivo',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(find.text('Detersivo'), findsOneWidget);
    expect(find.text('Altro'), findsOneWidget);

    await tester.tap(find.byKey(const Key('row-item:farina|mass')));
    await settle(tester);
    final tile = tester.widget<CheckboxListTile>(
      find.byKey(const Key('row-item:farina|mass')),
    );
    expect(tile.value, isTrue);
  });

  // Covers: SHOP-7, SHOP-8
  appTest('adding a meal with more flour unchecks flour', seed: seedWeek, (
    tester,
    app,
  ) async {
    await openShopping(tester);
    await tester.tap(find.byKey(const Key('row-item:farina|mass')));
    await settle(tester);
    final recipes = (await tester.runAsync(
      () => DriftRecipeRepository(app.db).watchAll().first,
    ))!;
    await tester.runAsync(
      () => DriftPlanRepository(app.db).addItem(
        SlotId(thu.addDays(2), MealType.lunch),
        RecipeItem(recipeId: recipes.single.id, servings: 4),
      ),
    );
    await settle(tester);
    expect(find.text('500 g'), findsOneWidget);
    final tile = tester.widget<CheckboxListTile>(
      find.byKey(const Key('row-item:farina|mass')),
    );
    expect(tile.value, isFalse);
  });

  // Covers: SHOP-1
  appTest('week navigation shows another week', seed: seedWeek, (
    tester,
    app,
  ) async {
    await openShopping(tester);
    await tester.tap(find.byTooltip('Settimana successiva'));
    await settle(tester);
    expect(find.text('La lista è vuota'), findsOneWidget);
  });
}
