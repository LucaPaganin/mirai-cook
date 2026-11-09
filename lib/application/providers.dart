import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/backup/backup_target.dart';
import '../data/backup/drive_backup.dart';
import '../data/backup/local_database_files.dart';
import '../data/background_scheduler.dart';
import '../data/db/app_database.dart';
import '../data/db/drift_repositories.dart';
import '../data/http_client.dart';
import '../data/repositories.dart';
import '../data/share_intent.dart';
import '../data/system_clock.dart';
import '../data/thumbnailer.dart';
import '../domain/calendar.dart';
import '../domain/clock.dart';
import '../domain/meal.dart';
import '../domain/recipe.dart';
import '../domain/shopping.dart';
import '../domain/store_section.dart';
import '../domain/suggestion_ranker.dart';
import 'backup_service.dart';
import 'recipe_importer.dart';

part 'providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure (override these in tests)
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const SystemClock();

@Riverpod(keepAlive: true)
DatabaseFiles databaseFiles(Ref ref) => const LocalDatabaseFiles();

AppDatabase openAppDatabase(DatabaseFiles files) => AppDatabase(
  driftDatabase(
    name: 'mirai_cook',
    native: DriftNativeOptions(
      databasePath: () async => (await files.databaseFile()).path,
    ),
  ),
);

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = openAppDatabase(ref.watch(databaseFilesProvider));
  ref.onDispose(() async {
    try {
      await db.close();
    } on Object {
      // Already closed by a restore.
    }
  });
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

/// Theme mode from settings (UI-1).
@riverpod
Stream<ThemeMode> themeMode(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.themeMode)
    .map(
      (v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
    );

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

/// Recipe book list filtered by title and tags (RCP-9). [tagKeys] is the
/// sorted, `|`-joined set of selected tag keys (a value type for the family).
@riverpod
Stream<List<RecipeSummary>> filteredRecipes(
  Ref ref,
  String query,
  String tagKeys,
) => ref
    .watch(recipeRepositoryProvider)
    .watchAll(
      query: query,
      tags: tagKeys.isEmpty ? const {} : tagKeys.split('|').toSet(),
    );

@riverpod
Stream<List<String>> recipeTags(Ref ref) =>
    ref.watch(recipeRepositoryProvider).watchTags();

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

// ---------------------------------------------------------------------------
// Import
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
HttpClient httpClient(Ref ref) => PackageHttpClient();

@Riverpod(keepAlive: true)
Thumbnailer thumbnailer(Ref ref) => const ImageThumbnailer();

@riverpod
RecipeImporter recipeImporter(Ref ref) => RecipeImporter(
  http: ref.watch(httpClientProvider),
  recipes: ref.watch(recipeRepositoryProvider),
  thumbnailer: ref.watch(thumbnailerProvider),
);

@Riverpod(keepAlive: true)
ShareIntentSource shareIntentSource(Ref ref) =>
    MethodChannelShareIntentSource();

// ---------------------------------------------------------------------------
// Backup
// ---------------------------------------------------------------------------

/// Web OAuth client id, passed with --dart-define (see README).
const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

@Riverpod(keepAlive: true)
BackupAccount backupAccount(Ref ref) => GoogleDriveAccount(
  ref.watch(clockProvider),
  serverClientId: googleServerClientId,
);

@Riverpod(keepAlive: true)
BackgroundScheduler? backgroundScheduler(Ref ref) => null;

@Riverpod(keepAlive: true)
BackupService backupService(Ref ref) => BackupService(
  db: ref.watch(appDatabaseProvider),
  settings: ref.watch(settingsRepositoryProvider),
  clock: ref.watch(clockProvider),
  files: ref.watch(databaseFilesProvider),
);

@Riverpod(keepAlive: true)
ChangeTracker changeTracker(Ref ref) {
  final tracker = ChangeTracker(
    ref.watch(appDatabaseProvider),
    ref.watch(backupServiceProvider),
  )..start();
  ref.onDispose(tracker.stop);
  return tracker;
}

@riverpod
Stream<String?> setting(Ref ref, String key) =>
    ref.watch(settingsRepositoryProvider).watch(key);

@Riverpod(keepAlive: true)
BackupController backupController(Ref ref) => BackupController(ref);

/// First launch with an empty database (DATA-14).
@riverpod
Future<bool> needsOnboarding(Ref ref) async {
  final settings = ref.watch(settingsRepositoryProvider);
  if (await settings.get(SettingKeys.onboardingDone) != null) return false;
  final recipes = await ref.watch(recipeListProvider('').future);
  if (recipes.isNotEmpty) return false;
  return !await ref.watch(planRepositoryProvider).hasAnyItems();
}

/// UI- and background-facing backup operations.
class BackupController {
  BackupController(this._ref);

  final Ref _ref;

  BackupAccount get _account => _ref.read(backupAccountProvider);
  BackupService get _service => _ref.read(backupServiceProvider);
  SettingsRepository get _settings => _ref.read(settingsRepositoryProvider);

  /// DATA-12: interactive sign-in, then daily background backups.
  Future<String> connect() async {
    final email = await _account.connect();
    await _settings.set(SettingKeys.backupAccount, email);
    await _service.markChanged();
    await _ref.read(backgroundSchedulerProvider)?.scheduleDailyBackup();
    return email;
  }

  /// DATA-17: snapshots stay on Drive.
  Future<void> disconnect() async {
    await _account.disconnect();
    await _settings.set(SettingKeys.backupAccount, null);
  }

  Future<BackupTarget> _target() async {
    final target = await _account.silentTarget();
    if (target != null) return target;
    await connect();
    return (await _account.silentTarget())!;
  }

  Future<BackupOutcome> backupNow() async => _service.backup(await _target());

  /// DATA-3, DATA-4: silent; failures are recorded for retry (DATA-11).
  Future<BackupOutcome> backupIfNeeded() async {
    try {
      if (!await _service.isConfigured()) {
        return const BackupSkipped('Backup non configurato');
      }
      return await _service.backupIfNeeded(await _account.silentTarget());
    } on Object catch (e) {
      await _settings.set(SettingKeys.lastBackupError, '$e');
      return BackupFailed('$e');
    }
  }

  Future<List<SnapshotInfo>> listSnapshots() async => (await _target()).list();

  Future<RestoreOutcome> restore(SnapshotInfo snapshot) async {
    final email = await _settings.get(SettingKeys.backupAccount);
    final outcome = await _service.restore(
      await _target(),
      snapshot,
      (f) => replaceDatabase(_ref, f),
    );
    if (outcome is RestoreDone) await _afterRestore(email);
    return outcome;
  }

  Future<bool> canUndoRestore() async =>
      (await _service.listLocalSnapshots()).isNotEmpty;

  /// DATA-16: puts back the copy taken before the last restore.
  Future<RestoreOutcome> undoRestore() async {
    final email = await _settings.get(SettingKeys.backupAccount);
    final snapshots = await _service.listLocalSnapshots();
    if (snapshots.isEmpty) {
      return const RestoreFailed('Nessuna copia locale disponibile');
    }
    final latest = snapshots.first;
    final outcome = await _service.restoreFile(
      latest,
      (f) => replaceDatabase(_ref, f),
    );
    if (outcome is RestoreDone) {
      // Do not offer to undo the undo with the same file.
      await latest.delete();
      await _afterRestore(email);
    }
    return outcome;
  }

  /// Device-specific settings survive the swap; the restored data counts
  /// as already backed up.
  Future<void> _afterRestore(String? email) async {
    final settings = _ref.read(settingsRepositoryProvider);
    final now = _ref.read(clockProvider).now().toUtc().toIso8601String();
    await settings.set(SettingKeys.backupAccount, email);
    await settings.set(SettingKeys.onboardingDone, '1');
    await settings.set(SettingKeys.lastBackupAt, now);
    await settings.set(SettingKeys.lastChangeAt, now);
    _ref.invalidate(needsOnboardingProvider);
  }
}

/// Closes the live database, swaps the file and reopens it (DATA-8, DATA-9).
Future<void> replaceDatabase(Ref ref, File source) async {
  final files = ref.read(databaseFilesProvider);
  final target = await files.databaseFile();
  await ref.read(appDatabaseProvider).close();
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final f = File('${target.path}$suffix');
    if (await f.exists()) await f.delete();
  }
  await source.copy(target.path);
  ref.invalidate(appDatabaseProvider);
}
