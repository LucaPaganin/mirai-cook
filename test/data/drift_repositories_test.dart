import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/data/db/app_database.dart';
import 'package:mirai_cook/data/db/drift_repositories.dart';
import 'package:mirai_cook/domain/calendar.dart';
import 'package:mirai_cook/domain/meal.dart';
import 'package:mirai_cook/domain/recipe.dart';
import 'package:mirai_cook/domain/store_section.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftRecipeRepository recipes;
  late DriftPlanRepository plan;
  late DriftShoppingRepository shopping;
  late DriftSettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    recipes = DriftRecipeRepository(db);
    plan = DriftPlanRepository(db);
    shopping = DriftShoppingRepository(db);
    settings = DriftSettingsRepository(db);
  });
  tearDown(() => db.close());

  const monday = CalendarDate(2026, 11, 2);
  final week = Week.containing(monday);
  final lunchMon = SlotId(monday, MealType.lunch);
  final dinnerMon = SlotId(monday, MealType.dinner);

  Recipe sample({String title = 'Carbonara', String? url}) => Recipe(
    title: title,
    servings: 4,
    steps: const ['Cuoci la pasta', 'Unisci le uova'],
    sourceUrl: url,
    thumbnail: const [1, 2, 3],
    ingredients: const [
      IngredientLine(
        original: '320 g spaghetti',
        quantity: 320,
        unit: 'g',
        name: 'spaghetti',
      ),
      IngredientLine(original: 'Pepe q.b.', name: 'Pepe'),
    ],
  );

  group('RecipeRepository', () {
    // Covers: RCP-2, RCP-3, RCP-5, DATA-1
    test('saves and loads all fields, including original lines', () async {
      final id = await recipes.save(sample(url: 'https://x.it/c'));
      final r = (await recipes.get(id))!;
      expect(r.title, 'Carbonara');
      expect(r.servings, 4);
      expect(r.steps, ['Cuoci la pasta', 'Unisci le uova']);
      expect(r.sourceUrl, 'https://x.it/c');
      expect(r.thumbnail, [1, 2, 3]);
      expect(r.ingredients, sample().ingredients);
    });

    // Covers: RCP-5
    test('editing replaces ingredients; deleting removes the recipe', () async {
      final id = await recipes.save(sample());
      await recipes.save(
        sample().copyWith(
          id: id,
          title: 'Carbonara light',
          ingredients: const [IngredientLine(original: 'Uova 2')],
        ),
      );
      final r = (await recipes.get(id))!;
      expect(r.title, 'Carbonara light');
      expect(r.ingredients.map((i) => i.original), ['Uova 2']);
      await recipes.delete(id);
      expect(await recipes.get(id), isNull);
    });

    // Covers: RCP-1
    test('lists recipes by title and filters by search', () async {
      await recipes.save(sample(title: 'Zuppa di farro'));
      await recipes.save(sample(title: 'amatriciana'));
      await recipes.save(sample(title: 'Carbonara'));
      final all = await recipes.watchAll().first;
      expect(all.map((r) => r.title), [
        'amatriciana',
        'Carbonara',
        'Zuppa di farro',
      ]);
      final found = await recipes.watchAll(query: 'ZUP').first;
      expect(found.map((r) => r.title), ['Zuppa di farro']);
      expect(await recipes.watchAll(query: '100%').first, isEmpty);
    });

    // Covers: RCP-6
    test('deleting a planned recipe turns slot items into free text', () async {
      final id = await recipes.save(sample());
      await plan.addItem(lunchMon, RecipeItem(recipeId: id, servings: 2));
      await recipes.delete(id);
      final slots = await plan.getRange(week.monday, week.sunday);
      expect(slots[lunchMon], [const FreeTextItem('Carbonara')]);
    });

    // Covers: IMP-9
    test('finds a recipe by source URL', () async {
      await recipes.save(sample(url: 'https://x.it/c'));
      expect(
        (await recipes.findBySourceUrl('https://x.it/c'))?.title,
        'Carbonara',
      );
      expect(await recipes.findBySourceUrl('https://x.it/other'), isNull);
    });
  });

  group('PlanRepository', () {
    // Covers: PLAN-3, PLAN-15, PLAN-16
    test('slots hold ordered items keyed by date and meal', () async {
      final id = await recipes.save(sample());
      await plan.addItem(lunchMon, const FreeTextItem('Insalata'));
      await plan.addItem(lunchMon, RecipeItem(recipeId: id, servings: 1));
      await plan.addItem(dinnerMon, const FreeTextItem('Pizza'));
      var slots = await plan.getRange(week.monday, week.sunday);
      expect(slots[lunchMon], [
        const FreeTextItem('Insalata'),
        RecipeItem(recipeId: id, servings: 1),
      ]);
      await plan.removeItemAt(lunchMon, 0);
      await plan.addItem(lunchMon, const FreeTextItem('Frutta'));
      slots = await plan.getRange(week.monday, week.sunday);
      expect(slots[lunchMon], [
        RecipeItem(recipeId: id, servings: 1),
        const FreeTextItem('Frutta'),
      ]);
      expect(slots[dinnerMon], [const FreeTextItem('Pizza')]);
    });

    // Covers: PLAN-12
    test('servings can be changed on recipe items only', () async {
      final id = await recipes.save(sample());
      await plan.addItem(lunchMon, const FreeTextItem('Pane'));
      await plan.addItem(lunchMon, RecipeItem(recipeId: id, servings: 1));
      await plan.setServingsAt(lunchMon, 1, 3);
      await plan.setServingsAt(lunchMon, 0, 3);
      final slots = await plan.getRange(week.monday, week.sunday);
      expect(slots[lunchMon], [
        const FreeTextItem('Pane'),
        RecipeItem(recipeId: id, servings: 3),
      ]);
    });

    // Covers: PLAN-9
    test('move and copy transfer all items of a slot', () async {
      await plan.addItem(lunchMon, const FreeTextItem('A'));
      await plan.addItem(lunchMon, const FreeTextItem('B'));
      await plan.addItem(dinnerMon, const FreeTextItem('C'));
      await plan.transferSlot(lunchMon, dinnerMon, move: false);
      var slots = await plan.getRange(week.monday, week.sunday);
      expect(slots[lunchMon], hasLength(2));
      expect(slots[dinnerMon]!.map((i) => (i as FreeTextItem).text), [
        'C',
        'A',
        'B',
      ]);
      final tue = SlotId(monday.addDays(1), MealType.breakfast);
      await plan.transferSlot(lunchMon, tue, move: true);
      slots = await plan.getRange(week.monday, week.sunday);
      expect(slots[lunchMon], isNull);
      expect(slots[tue], hasLength(2));
    });

    // Covers: PLAN-10, PLAN-11
    test('duplicate previous week replaces the target week', () async {
      final prevMon = SlotId(week.previous.monday, MealType.dinner);
      await plan.addItem(prevMon, const FreeTextItem('Risotto'));
      await plan.addItem(lunchMon, const FreeTextItem('Da sovrascrivere'));
      expect(await plan.hasItems(week), isTrue);
      expect(await plan.hasItems(week.next), isFalse);
      await plan.duplicatePreviousWeek(week);
      final slots = await plan.getRange(week.monday, week.sunday);
      expect(slots.keys, [dinnerMon]);
      expect(slots[dinnerMon], [const FreeTextItem('Risotto')]);
    });

    // Covers: PLAN-6
    test('suggestion candidates carry their usage dates', () async {
      final id = await recipes.save(sample());
      await plan.addItem(lunchMon, RecipeItem(recipeId: id, servings: 1));
      await plan.addItem(dinnerMon, const FreeTextItem('Avanzi'));
      await plan.addItem(
        SlotId(monday.addDays(1), MealType.dinner),
        const FreeTextItem('avanzi'),
      );
      final c = await plan.suggestionCandidates();
      expect(c.singleWhere((s) => s.recipeId == id).uses, [monday]);
      expect(c.singleWhere((s) => !s.isRecipe).uses, hasLength(2));
    });
  });

  group('ShoppingRepository', () {
    // Covers: SHOP-5, SHOP-6
    test('manual items and checks persist per week', () async {
      await shopping.addManualItem(week, ' Detersivo ');
      var items = await shopping.watchManualItems(week).first;
      expect(items.single.text, 'Detersivo');
      await shopping.setManualChecked(items.single.id, true);
      items = await shopping.watchManualItems(week).first;
      expect(items.single.checked, isTrue);
      expect(await shopping.watchManualItems(week.next).first, isEmpty);
      await shopping.removeManualItem(items.single.id);
      expect(await shopping.watchManualItems(week).first, isEmpty);

      await shopping.check(week, 'item:farina|mass', 500);
      await shopping.check(week, 'line:sale q.b.', null);
      expect(await shopping.watchChecks(week).first, {
        'item:farina|mass': 500,
        'line:sale q.b.': null,
      });
      await shopping.uncheck(week, 'line:sale q.b.');
      expect((await shopping.watchChecks(week).first).keys, [
        'item:farina|mass',
      ]);
    });

    // Covers: SHOP-12, SHOP-15
    test('aliases and section overrides are remembered', () async {
      await shopping.addAlias('olio evo', 'olio extravergine');
      await shopping.addAlias('x', 'x');
      expect(await shopping.watchAliases().first, {
        'olio evo': 'olio extravergine',
      });
      await shopping.setSectionOverride('latte', StoreSection.other);
      expect(await shopping.watchSectionOverrides().first, {
        'latte': StoreSection.other,
      });
    });
  });

  // Covers: PLAN-18
  test('settings store and clear values', () async {
    expect(await settings.get('k'), isNull);
    await settings.set('k', '2');
    expect(await settings.get('k'), '2');
    await settings.set('k', null);
    expect(await settings.get('k'), isNull);
  });
}
