import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/calendar.dart';
import '../../domain/meal.dart';
import '../../domain/recipe.dart';
import '../../domain/shopping.dart';
import '../../domain/store_section.dart';
import '../../domain/suggestion_ranker.dart';
import '../repositories.dart';
import 'app_database.dart';

class DriftRecipeRepository implements RecipeRepository {
  DriftRecipeRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<RecipeSummary>> watchAll({String query = ''}) {
    final q = _db.select(_db.recipes)
      ..orderBy([
        (r) => OrderingTerm(expression: r.title.collate(Collate.noCase)),
      ]);
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      q.where(
        (r) => r.title.like('%${_escapeLike(trimmed)}%', escapeChar: r'\'),
      );
    }
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          RecipeSummary(id: r.id, title: r.title, thumbnail: r.thumbnail),
      ],
    );
  }

  @override
  Stream<Recipe?> watch(int id) {
    final recipeQuery = _db.select(_db.recipes)..where((r) => r.id.equals(id));
    return recipeQuery.watchSingleOrNull().asyncMap(
      (row) async => row == null ? null : _withIngredients(row),
    );
  }

  @override
  Future<Recipe?> get(int id) async {
    final row = await (_db.select(
      _db.recipes,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    return row == null ? null : _withIngredients(row);
  }

  @override
  Future<List<Recipe>> getMany(Iterable<int> ids) async {
    final idList = ids.toSet().toList();
    if (idList.isEmpty) return const [];
    final rows = await (_db.select(
      _db.recipes,
    )..where((r) => r.id.isIn(idList))).get();
    final lines =
        await (_db.select(_db.ingredientLines)
              ..where((l) => l.recipeId.isIn(idList))
              ..orderBy([(l) => OrderingTerm(expression: l.position)]))
            .get();
    final byRecipe = <int, List<IngredientLineRow>>{};
    for (final l in lines) {
      (byRecipe[l.recipeId] ??= []).add(l);
    }
    return [for (final r in rows) _toDomain(r, byRecipe[r.id] ?? const [])];
  }

  @override
  Future<int> save(Recipe recipe) => _db.transaction(() async {
    final companion = RecipesCompanion(
      title: Value(recipe.title),
      servings: Value(recipe.servings),
      steps: Value(jsonEncode(recipe.steps)),
      sourceUrl: Value(recipe.sourceUrl),
      thumbnail: Value(
        recipe.thumbnail == null ? null : Uint8List.fromList(recipe.thumbnail!),
      ),
    );
    final int id;
    if (recipe.id == null) {
      id = await _db.into(_db.recipes).insert(companion);
    } else {
      id = recipe.id!;
      await (_db.update(
        _db.recipes,
      )..where((r) => r.id.equals(id))).write(companion);
      await (_db.delete(
        _db.ingredientLines,
      )..where((l) => l.recipeId.equals(id))).go();
    }
    await _db.batch((b) {
      b.insertAll(_db.ingredientLines, [
        for (final (i, ing) in recipe.ingredients.indexed)
          IngredientLinesCompanion.insert(
            recipeId: id,
            position: i,
            original: ing.original,
            quantity: Value(ing.quantity),
            unit: Value(ing.unit),
            name: Value(ing.name),
          ),
      ]);
    });
    return id;
  });

  @override
  Future<void> delete(int id) => _db.transaction(() async {
    final recipe = await (_db.select(
      _db.recipes,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (recipe == null) return;
    await (_db.update(
      _db.slotItems,
    )..where((s) => s.recipeId.equals(id))).write(
      SlotItemsCompanion(
        freeText: Value(recipe.title),
        recipeId: const Value(null),
        servings: const Value(null),
      ),
    );
    await (_db.delete(_db.recipes)..where((r) => r.id.equals(id))).go();
  });

  @override
  Future<Recipe?> findBySourceUrl(String url) async {
    final row =
        await (_db.select(_db.recipes)
              ..where((r) => r.sourceUrl.equals(url))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _withIngredients(row);
  }

  Future<Recipe> _withIngredients(RecipeRow row) async {
    final lines =
        await (_db.select(_db.ingredientLines)
              ..where((l) => l.recipeId.equals(row.id))
              ..orderBy([(l) => OrderingTerm(expression: l.position)]))
            .get();
    return _toDomain(row, lines);
  }

  Recipe _toDomain(RecipeRow row, List<IngredientLineRow> lines) => Recipe(
    id: row.id,
    title: row.title,
    servings: row.servings,
    steps: (jsonDecode(row.steps) as List).cast<String>(),
    sourceUrl: row.sourceUrl,
    thumbnail: row.thumbnail,
    ingredients: [
      for (final l in lines)
        IngredientLine(
          original: l.original,
          quantity: l.quantity,
          unit: l.unit,
          name: l.name,
        ),
    ],
  );

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}

class DriftPlanRepository implements PlanRepository {
  DriftPlanRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$SlotItemsTable, SlotItemRow> _rangeQuery(
    CalendarDate from,
    CalendarDate to,
  ) {
    return _db.select(_db.slotItems)
      ..where((s) => s.date.isBetweenValues(from.toInt(), to.toInt()))
      ..orderBy([
        (s) => OrderingTerm(expression: s.date),
        (s) => OrderingTerm(expression: s.meal),
        (s) => OrderingTerm(expression: s.position),
      ]);
  }

  @override
  Stream<Map<SlotId, List<SlotItem>>> watchRange(
    CalendarDate from,
    CalendarDate to,
  ) => _rangeQuery(from, to).watch().map(_group);

  @override
  Future<Map<SlotId, List<SlotItem>>> getRange(
    CalendarDate from,
    CalendarDate to,
  ) async => _group(await _rangeQuery(from, to).get());

  Map<SlotId, List<SlotItem>> _group(List<SlotItemRow> rows) {
    final result = <SlotId, List<SlotItem>>{};
    for (final r in rows) {
      (result[_slotIdOf(r)] ??= []).add(_toDomain(r));
    }
    return result;
  }

  @override
  Future<void> addItem(SlotId slot, SlotItem item) => _db.transaction(() async {
    final next = (await _rows(slot)).length;
    await _db.into(_db.slotItems).insert(_companion(slot, next, item));
  });

  @override
  Future<void> removeItemAt(SlotId slot, int index) =>
      _db.transaction(() async {
        final rows = await _rows(slot);
        if (index < 0 || index >= rows.length) return;
        await (_db.delete(
          _db.slotItems,
        )..where((s) => s.id.equals(rows[index].id))).go();
        for (var i = index + 1; i < rows.length; i++) {
          await (_db.update(_db.slotItems)
                ..where((s) => s.id.equals(rows[i].id)))
              .write(SlotItemsCompanion(position: Value(i - 1)));
        }
      });

  @override
  Future<void> clearSlot(SlotId slot) => _deleteSlot(slot);

  @override
  Future<void> setServingsAt(SlotId slot, int index, double servings) =>
      _db.transaction(() async {
        final rows = await _rows(slot);
        if (index < 0 || index >= rows.length) return;
        final row = rows[index];
        if (row.recipeId == null) return;
        await (_db.update(_db.slotItems)..where((s) => s.id.equals(row.id)))
            .write(SlotItemsCompanion(servings: Value(servings)));
      });

  @override
  Future<void> transferSlot(SlotId from, SlotId to, {required bool move}) =>
      _db.transaction(() async {
        if (from == to) return;
        final source = await _rows(from);
        var next = (await _rows(to)).length;
        for (final r in source) {
          await _db
              .into(_db.slotItems)
              .insert(_companion(to, next++, _toDomain(r)));
        }
        if (move) await _deleteSlot(from);
      });

  @override
  Future<void> duplicatePreviousWeek(Week target) => _db.transaction(() async {
    final prev = target.previous;
    await (_db.delete(_db.slotItems)..where(
          (s) => s.date.isBetweenValues(
            target.monday.toInt(),
            target.sunday.toInt(),
          ),
        ))
        .go();
    final rows = await _rangeQuery(prev.monday, prev.sunday).get();
    await _db.batch((b) {
      b.insertAll(_db.slotItems, [
        for (final r in rows)
          SlotItemsCompanion.insert(
            date: CalendarDate.fromInt(r.date).addDays(7).toInt(),
            meal: r.meal,
            position: r.position,
            freeText: Value(r.freeText),
            recipeId: Value(r.recipeId),
            servings: Value(r.servings),
          ),
      ]);
    });
  });

  @override
  Future<bool> hasItems(Week week) async {
    final count = _db.slotItems.id.count();
    final q = _db.selectOnly(_db.slotItems)
      ..addColumns([count])
      ..where(
        _db.slotItems.date.isBetweenValues(
          week.monday.toInt(),
          week.sunday.toInt(),
        ),
      );
    return (await q.getSingle().then((r) => r.read(count)) ?? 0) > 0;
  }

  @override
  Future<bool> hasAnyItems() async =>
      await (_db.select(_db.slotItems)..limit(1)).getSingleOrNull() != null;

  @override
  Future<List<Suggestion>> suggestionCandidates() async {
    final recipes = await _db.select(_db.recipes).get();
    final items = await _db.select(_db.slotItems).get();
    final recipeUses = <int, List<CalendarDate>>{};
    final textUses = <String, List<CalendarDate>>{};
    final textLabel = <String, String>{};
    for (final i in items) {
      final date = CalendarDate.fromInt(i.date);
      if (i.recipeId != null) {
        (recipeUses[i.recipeId!] ??= []).add(date);
      } else {
        final key = i.freeText!.trim().toLowerCase();
        textLabel.putIfAbsent(key, () => i.freeText!.trim());
        (textUses[key] ??= []).add(date);
      }
    }
    return [
      for (final r in recipes)
        Suggestion.recipe(r.id, r.title, recipeUses[r.id] ?? const []),
      for (final e in textUses.entries)
        Suggestion.freeText(textLabel[e.key]!, e.value),
    ];
  }

  Future<List<SlotItemRow>> _rows(SlotId slot) =>
      (_db.select(_db.slotItems)
            ..where(
              (s) =>
                  s.date.equals(slot.date.toInt()) &
                  s.meal.equals(slot.meal.index),
            )
            ..orderBy([(s) => OrderingTerm(expression: s.position)]))
          .get();

  Future<void> _deleteSlot(SlotId slot) =>
      (_db.delete(_db.slotItems)..where(
            (s) =>
                s.date.equals(slot.date.toInt()) &
                s.meal.equals(slot.meal.index),
          ))
          .go();

  SlotItemsCompanion _companion(SlotId slot, int position, SlotItem item) =>
      SlotItemsCompanion.insert(
        date: slot.date.toInt(),
        meal: slot.meal.index,
        position: position,
        freeText: Value(item is FreeTextItem ? item.text : null),
        recipeId: Value(item is RecipeItem ? item.recipeId : null),
        servings: Value(item is RecipeItem ? item.servings : null),
      );

  SlotId _slotIdOf(SlotItemRow r) =>
      SlotId(CalendarDate.fromInt(r.date), MealType.values[r.meal]);

  SlotItem _toDomain(SlotItemRow r) => r.recipeId != null
      ? RecipeItem(recipeId: r.recipeId!, servings: r.servings ?? 1)
      : FreeTextItem(r.freeText!);
}

class DriftShoppingRepository implements ShoppingRepository {
  DriftShoppingRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ManualItem>> watchManualItems(Week week) =>
      (_db.select(
        _db.manualShoppingItems,
      )..where((m) => m.week.equals(week.monday.toInt()))).watch().map(
        (rows) => [
          for (final r in rows)
            ManualItem(id: r.id, text: r.label, checked: r.checked),
        ],
      );

  @override
  Stream<Map<String, double?>> watchChecks(Week week) =>
      (_db.select(_db.shoppingChecks)
            ..where((c) => c.week.equals(week.monday.toInt())))
          .watch()
          .map((rows) => {for (final r in rows) r.entryKey: r.checkedQuantity});

  @override
  Stream<Map<String, String>> watchAliases() => _db
      .select(_db.ingredientAliases)
      .watch()
      .map((rows) => {for (final r in rows) r.fromName: r.toName});

  @override
  Stream<Map<String, StoreSection>> watchSectionOverrides() => _db
      .select(_db.sectionOverrides)
      .watch()
      .map(
        (rows) => {
          for (final r in rows) r.name: StoreSection.values[r.section],
        },
      );

  @override
  Future<void> check(Week week, String key, double? baseQuantity) => _db
      .into(_db.shoppingChecks)
      .insertOnConflictUpdate(
        ShoppingChecksCompanion.insert(
          week: week.monday.toInt(),
          entryKey: key,
          checkedQuantity: Value(baseQuantity),
        ),
      );

  @override
  Future<void> uncheck(Week week, String key) =>
      (_db.delete(_db.shoppingChecks)..where(
            (c) => c.week.equals(week.monday.toInt()) & c.entryKey.equals(key),
          ))
          .go();

  @override
  Future<void> addManualItem(Week week, String label) => _db
      .into(_db.manualShoppingItems)
      .insert(
        ManualShoppingItemsCompanion.insert(
          week: week.monday.toInt(),
          label: label.trim(),
        ),
      );

  @override
  Future<void> setManualChecked(int id, bool checked) =>
      (_db.update(_db.manualShoppingItems)..where((m) => m.id.equals(id)))
          .write(ManualShoppingItemsCompanion(checked: Value(checked)));

  @override
  Future<void> removeManualItem(int id) =>
      (_db.delete(_db.manualShoppingItems)..where((m) => m.id.equals(id))).go();

  @override
  Future<void> addAlias(String fromName, String toName) async {
    if (fromName == toName) return;
    await _db
        .into(_db.ingredientAliases)
        .insertOnConflictUpdate(
          IngredientAliasesCompanion.insert(fromName: fromName, toName: toName),
        );
  }

  @override
  Future<void> setSectionOverride(String name, StoreSection section) => _db
      .into(_db.sectionOverrides)
      .insertOnConflictUpdate(
        SectionOverridesCompanion.insert(name: name, section: section.index),
      );
}

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$SettingsTable, SettingRow> _q(String key) =>
      _db.select(_db.settings)..where((s) => s.key.equals(key));

  @override
  Stream<String?> watch(String key) =>
      _q(key).watchSingleOrNull().map((r) => r?.value);

  @override
  Future<String?> get(String key) async =>
      (await _q(key).getSingleOrNull())?.value;

  @override
  Future<void> set(String key, String? value) async {
    if (value == null) {
      await (_db.delete(_db.settings)..where((s) => s.key.equals(key))).go();
    } else {
      await _db
          .into(_db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: key, value: value),
          );
    }
  }
}
