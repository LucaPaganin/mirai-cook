import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/db/app_database.dart';
import '../data/db/drift_repositories.dart';
import '../data/repositories.dart';
import '../data/system_clock.dart';
import '../domain/calendar.dart';
import '../domain/clock.dart';
import '../domain/meal.dart';
import '../domain/recipe.dart';
import '../domain/shopping.dart';
import '../domain/store_section.dart';
import '../domain/suggestion_ranker.dart';

part 'providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure (override these in tests)
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const SystemClock();

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(driftDatabase(name: 'mirai_cook'));
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
RecipeRepository recipeRepository(Ref ref) =>
    DriftRecipeRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
PlanRepository planRepository(Ref ref) =>
    DriftPlanRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
ShoppingRepository shoppingRepository(Ref ref) =>
    DriftShoppingRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    DriftSettingsRepository(ref.watch(appDatabaseProvider));

// ---------------------------------------------------------------------------
// Plan
// ---------------------------------------------------------------------------

/// Today's date from the injected clock (PLAN-13).
@riverpod
CalendarDate today(Ref ref) =>
    CalendarDate.fromDateTime(ref.watch(clockProvider).now());

@riverpod
Week currentWeek(Ref ref) => Week.containing(ref.watch(todayProvider));

@riverpod
Stream<Map<SlotId, List<SlotItem>>> weekPlan(Ref ref, Week week) =>
    ref.watch(planRepositoryProvider).watchRange(week.monday, week.sunday);

/// Default servings for new recipe items (PLAN-12, PLAN-18).
@riverpod
Stream<double> defaultServings(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.defaultServings)
    .map((v) => double.tryParse(v ?? '') ?? 1);

@riverpod
Future<List<Suggestion>> slotSuggestions(Ref ref, String query) async {
  // Recompute when recipes change.
  await ref.watch(recipeListProvider('').future);
  final candidates = await ref
      .watch(planRepositoryProvider)
      .suggestionCandidates();
  return const SuggestionRanker().rank(
    query,
    candidates,
    ref.watch(todayProvider),
  );
}

// ---------------------------------------------------------------------------
// Recipes
// ---------------------------------------------------------------------------

@riverpod
Stream<List<RecipeSummary>> recipeList(Ref ref, String query) =>
    ref.watch(recipeRepositoryProvider).watchAll(query: query);

@riverpod
Future<Map<int, RecipeSummary>> recipeIndex(Ref ref) async {
  final all = await ref.watch(recipeListProvider('').future);
  return {for (final r in all) r.id: r};
}

@riverpod
Stream<Recipe?> recipe(Ref ref, int id) =>
    ref.watch(recipeRepositoryProvider).watch(id);

// ---------------------------------------------------------------------------
// Shopping list
// ---------------------------------------------------------------------------

@riverpod
Stream<List<ManualItem>> manualItems(Ref ref, Week week) =>
    ref.watch(shoppingRepositoryProvider).watchManualItems(week);

@riverpod
Stream<Map<String, double?>> shoppingChecks(Ref ref, Week week) =>
    ref.watch(shoppingRepositoryProvider).watchChecks(week);

@riverpod
Stream<Map<String, String>> ingredientAliases(Ref ref) =>
    ref.watch(shoppingRepositoryProvider).watchAliases();

@riverpod
Stream<Map<String, StoreSection>> sectionOverrides(Ref ref) =>
    ref.watch(shoppingRepositoryProvider).watchSectionOverrides();

/// Recipe-derived entries, recomputed whenever the plan, recipes or aliases
/// change (SHOP-1..4, SHOP-7, SHOP-9).
@riverpod
Future<List<ShoppingEntry>> shoppingEntries(Ref ref, Week week) async {
  final plan = await ref.watch(weekPlanProvider(week).future);
  await ref.watch(recipeListProvider('').future); // recipe edits
  final aliases = await ref.watch(ingredientAliasesProvider.future);
  final items = [
    for (final slot in plan.values)
      for (final item in slot)
        if (item is RecipeItem) item,
  ];
  final recipes = {
    for (final r
        in await ref
            .watch(recipeRepositoryProvider)
            .getMany(items.map((i) => i.recipeId)))
      r.id!: r,
  };
  return ShoppingAggregator(aliases: aliases).aggregate([
    for (final i in items)
      if (recipes[i.recipeId] case final r?) PlannedRecipe(r, i.servings),
  ]);
}

@riverpod
Future<List<ShoppingRow>> shoppingList(Ref ref, Week week) async {
  final entries = await ref.watch(shoppingEntriesProvider(week).future);
  final manual = await ref.watch(manualItemsProvider(week).future);
  final checks = await ref.watch(shoppingChecksProvider(week).future);
  final overrides = await ref.watch(sectionOverridesProvider.future);
  return ShoppingListBuilder(SectionResolver(overrides: overrides))
      .build(entries: entries, manualItems: manual, checks: checks);
}
