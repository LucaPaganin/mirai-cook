import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/domain/recipe.dart';
import 'package:mirai_cook/domain/shopping.dart';
import 'package:mirai_cook/domain/store_section.dart';
import 'package:mirai_cook/domain/units.dart';

IngredientLine ing(String original, double? q, String? unit, String? name) =>
    IngredientLine(original: original, quantity: q, unit: unit, name: name);

Recipe recipe(int id, double servings, List<IngredientLine> ingredients) =>
    Recipe(id: id, title: 'R$id', servings: servings, ingredients: ingredients);

ShoppingEntry byName(List<ShoppingEntry> e, String name) =>
    e.singleWhere((x) => x.name == name);

void main() {
  final pasta = recipe(1, 4, [
    ing('320 g spaghetti', 320, 'g', 'spaghetti'),
    ing('2 spicchi d\'aglio', 2, 'spicchio', 'aglio'),
    ing('Sale q.b.', null, null, 'Sale'),
  ]);
  final cake = recipe(2, 8, [
    ing('Farina 00 500 g', 500, 'g', 'Farina 00'),
    ing('4 uova', 4, null, 'uova'),
    ing('200 ml latte', 200, 'ml', 'latte'),
  ]);
  final bread = recipe(3, 2, [
    ing('1 kg farina 00', 1, 'kg', 'farina 00'),
    ing('2 uova', 2, null, 'Uova'),
    ing('1 cucchiaio di latte', 1, 'cucchiaio', 'latte'),
    ing('Sale q.b.', null, null, 'Sale'),
    ing('un pizzico di sale', null, null, 'sale'),
  ]);

  const aggregator = ShoppingAggregator();

  // Covers: SHOP-1, SHOP-2
  test(
    'collects and scales ingredients by item servings / recipe servings',
    () {
      final e = aggregator.aggregate([PlannedRecipe(pasta, 2)]);
      expect(byName(e, 'spaghetti').amount, const Amount(160, 'g'));
      expect(byName(e, 'aglio').amount, const Amount(1, 'spicchio'));
    },
  );

  // Covers: SHOP-2
  test('the same recipe planned twice adds up', () {
    final e = aggregator.aggregate([
      PlannedRecipe(pasta, 1),
      PlannedRecipe(pasta, 3),
    ]);
    expect(byName(e, 'spaghetti').amount, const Amount(320, 'g'));
  });

  // Covers: SHOP-3, SHOP-10, SHOP-11
  test('merges same normalized name and convertible units', () {
    final e = aggregator.aggregate([
      PlannedRecipe(cake, 8),
      PlannedRecipe(bread, 2),
    ]);
    expect(byName(e, 'farina 00').amount, const Amount(1.5, 'kg'));
    expect(byName(e, 'uova').amount, const Amount(6, null));
    // 200 ml + 1 cucchiaio (15 ml)
    expect(byName(e, 'latte').amount, const Amount(215, 'ml'));
  });

  // Covers: SHOP-3
  test('different dimensions stay on separate lines', () {
    final r = recipe(9, 1, [
      ing('100 g parmigiano', 100, 'g', 'parmigiano'),
      ing('1 pezzo parmigiano', 1, 'pezzo', 'parmigiano'),
      ing('2 parmigiano', 2, null, 'parmigiano'),
    ]);
    final e = aggregator.aggregate([PlannedRecipe(r, 1)]);
    expect(e.where((x) => x.name == 'parmigiano'), hasLength(3));
    expect(e.map((x) => x.key).toSet(), hasLength(3));
  });

  // Covers: SHOP-4
  test('lines without quantity are listed as original, not merged', () {
    final e = aggregator.aggregate([
      PlannedRecipe(pasta, 4),
      PlannedRecipe(bread, 2),
    ]);
    final unquantified = e.where((x) => x.amount == null).toList();
    expect(
      unquantified.map((x) => x.label),
      unorderedEquals(['Sale q.b.', 'un pizzico di sale']),
    );
  });

  // Covers: SHOP-12
  test('aliases redirect names before merging', () {
    final r = recipe(5, 1, [
      ing('2 cucchiai olio evo', 2, 'cucchiaio', 'olio evo'),
      ing('30 ml olio extravergine', 30, 'ml', 'olio extravergine'),
    ]);
    final e = const ShoppingAggregator(
      aliases: {'olio evo': 'olio extravergine'},
    ).aggregate([PlannedRecipe(r, 1)]);
    expect(e, hasLength(1));
    expect(e.single.amount, const Amount(60, 'ml'));
    expect(e.single.name, 'olio extravergine');
  });

  // Covers: SHOP-12
  test('alias chains resolve and cycles do not loop', () {
    expect(resolveAlias('a', {'a': 'b', 'b': 'c'}), 'c');
    expect(resolveAlias('a', {'a': 'b', 'b': 'a'}), isIn(['a', 'b']));
  });

  group('ShoppingListBuilder', () {
    final sections = SectionResolver();
    final builder = ShoppingListBuilder(sections);
    final entries = aggregator.aggregate([PlannedRecipe(cake, 8)]);
    final farinaKey = byName(entries, 'farina 00').key;

    // Covers: SHOP-5, SHOP-7
    test('includes manual items alongside computed ones', () {
      final rows = builder.build(
        entries: entries,
        manualItems: const [ManualItem(id: 1, text: 'Detersivo')],
        checks: const {},
      );
      expect(rows.map((r) => r.label), contains('Detersivo'));
      expect(
        rows.where((r) => r.manualId == 1).single.section,
        StoreSection.other,
      );
    });

    // Covers: SHOP-6, SHOP-7
    test('keeps checked state for items that still exist', () {
      final rows = builder.build(
        entries: entries,
        manualItems: const [ManualItem(id: 1, text: 'Pane', checked: true)],
        checks: {farinaKey: 500, 'gone': 1},
      );
      expect(rows.singleWhere((r) => r.key == farinaKey).checked, isTrue);
      expect(rows.singleWhere((r) => r.manualId == 1).checked, isTrue);
      expect(rows.where((r) => r.key == 'gone'), isEmpty);
    });

    // Covers: SHOP-8
    test('a checked item whose quantity grew is unchecked', () {
      final more = aggregator.aggregate([
        PlannedRecipe(cake, 8),
        PlannedRecipe(bread, 2),
      ]);
      final rows = builder.build(
        entries: more,
        manualItems: const [],
        checks: {farinaKey: 500},
      );
      expect(rows.singleWhere((r) => r.key == farinaKey).checked, isFalse);
    });

    // Covers: SHOP-8
    test('a checked item whose quantity shrank stays checked', () {
      final less = aggregator.aggregate([PlannedRecipe(cake, 4)]);
      final rows = builder.build(
        entries: less,
        manualItems: const [],
        checks: {farinaKey: 500},
      );
      expect(rows.singleWhere((r) => r.key == farinaKey).checked, isTrue);
    });

    // Covers: SHOP-13
    test('groups by section, alphabetical, checked items last', () {
      final rows = builder.build(
        entries: entries,
        manualItems: const [
          ManualItem(id: 1, text: 'Zucchine'),
          ManualItem(id: 2, text: 'Aglio', checked: true),
          ManualItem(id: 3, text: 'Mele'),
        ],
        checks: const {},
      );
      final produce = rows
          .where((r) => r.section == StoreSection.produce)
          .map((r) => r.label)
          .toList();
      expect(produce, ['Mele', 'Zucchine', 'Aglio']);
      final order = rows.map((r) => r.section.index).toList();
      expect(order, [...order]..sort());
    });
  });

  group('SectionResolver', () {
    // Covers: SHOP-14
    for (final (name, section) in [
      ('farina 00', StoreSection.pantry),
      ('pomodori pelati', StoreSection.pantry),
      ('pomodori', StoreSection.produce),
      ('latte', StoreSection.dairy),
      ('petto di pollo', StoreSection.meatFish),
      ('piselli surgelati', StoreSection.frozen),
      ('detersivo', StoreSection.other),
    ]) {
      test('$name -> $section', () {
        expect(SectionResolver().resolve(name), section);
      });
    }

    // Covers: SHOP-15
    test('user overrides win over the seed table', () {
      final r = SectionResolver(overrides: {'latte': StoreSection.other});
      expect(r.resolve('latte'), StoreSection.other);
    });
  });
}
