import '../domain/calendar.dart';
import '../domain/meal.dart';
import '../domain/recipe.dart';
import '../domain/shopping.dart';
import '../domain/store_section.dart';
import '../domain/suggestion_ranker.dart';

abstract interface class RecipeRepository {
  /// Recipes whose title matches [query] (case-insensitive) and that have
  /// all [tags], ordered by title (RCP-1, RCP-9).
  Stream<List<RecipeSummary>> watchAll({
    String query = '',
    Set<String> tags = const {},
  });

  /// Names of the tags used by at least one recipe, sorted (RCP-8, RCP-9).
  Stream<List<String>> watchTags();
  Stream<Recipe?> watch(int id);
  Future<Recipe?> get(int id);
  Future<List<Recipe>> getMany(Iterable<int> ids);

  /// Inserts or updates; returns the recipe id.
  Future<int> save(Recipe recipe);

  /// Deletes the recipe, turning slot items that reference it into free text
  /// with its title (RCP-6).
  Future<void> delete(int id);

  Future<Recipe?> findBySourceUrl(String url);
}

abstract interface class PlanRepository {
  /// All slots in [from]..[to] inclusive that have at least one item.
  Stream<Map<SlotId, List<SlotItem>>> watchRange(
    CalendarDate from,
    CalendarDate to,
  );
  Future<Map<SlotId, List<SlotItem>>> getRange(
    CalendarDate from,
    CalendarDate to,
  );

  Future<void> addItem(SlotId slot, SlotItem item);
  Future<void> removeItemAt(SlotId slot, int index);

  /// Removes all items of [slot] (PLAN-9).
  Future<void> clearSlot(SlotId slot);

  /// Turns free-text items whose normalized text equals [title] into
  /// references to [recipeId] with [servings] (PLAN-20). Returns how many
  /// items were linked.
  Future<int> linkFreeTextToRecipe(int recipeId, String title, double servings);
  Future<void> setServingsAt(SlotId slot, int index, double servings);

  /// Appends all items of [from] to [to]; with [move] [from] is emptied.
  Future<void> transferSlot(SlotId from, SlotId to, {required bool move});

  /// Replaces [target] with the items of the previous week (PLAN-10).
  Future<void> duplicatePreviousWeek(Week target);
  Future<bool> hasItems(Week week);
  Future<bool> hasAnyItems();

  /// Recipes and previously used free texts with their planned dates.
  Future<List<Suggestion>> suggestionCandidates();
}

abstract interface class ShoppingRepository {
  Stream<List<ManualItem>> watchManualItems(Week week);
  Stream<Map<String, double?>> watchChecks(Week week);
  Stream<Map<String, String>> watchAliases();
  Stream<Map<String, StoreSection>> watchSectionOverrides();

  Future<void> check(Week week, String key, double? baseQuantity);
  Future<void> uncheck(Week week, String key);
  Future<void> addManualItem(Week week, String label);
  Future<void> setManualChecked(int id, bool checked);
  Future<void> removeManualItem(int id);
  Future<void> addAlias(String fromName, String toName);
  Future<void> setSectionOverride(String name, StoreSection section);
}

abstract interface class SettingsRepository {
  Stream<String?> watch(String key);
  Future<String?> get(String key);
  Future<void> set(String key, String? value);
}

/// Known settings keys.
abstract final class SettingKeys {
  static const defaultServings = 'default_servings';
  static const backupKeepCount = 'backup_keep_count';
  static const lastBackupAt = 'last_backup_at';
  static const lastChangeAt = 'last_change_at';
  static const backupAccount = 'backup_account';
  static const lastBackupError = 'last_backup_error';
  static const onboardingDone = 'onboarding_done';
}
