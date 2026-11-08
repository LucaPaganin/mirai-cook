// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clock)
final clockProvider = ClockProvider._();

final class ClockProvider extends $FunctionalProvider<Clock, Clock, Clock>
    with $Provider<Clock> {
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<Clock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Clock create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Clock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Clock>(value),
    );
  }
}

String _$clockHash() => r'55214d6539f7396a3ae1aa23b06eea79fdac0ebe';

@ProviderFor(databaseFiles)
final databaseFilesProvider = DatabaseFilesProvider._();

final class DatabaseFilesProvider
    extends $FunctionalProvider<DatabaseFiles, DatabaseFiles, DatabaseFiles>
    with $Provider<DatabaseFiles> {
  DatabaseFilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseFilesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseFilesHash();

  @$internal
  @override
  $ProviderElement<DatabaseFiles> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DatabaseFiles create(Ref ref) {
    return databaseFiles(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DatabaseFiles value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DatabaseFiles>(value),
    );
  }
}

String _$databaseFilesHash() => r'7c54b856d60764f133e7f703fb341b530b2879cd';

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'1d32c5e6022201ef2946d197336afb6a250ef9cb';

@ProviderFor(recipeRepository)
final recipeRepositoryProvider = RecipeRepositoryProvider._();

final class RecipeRepositoryProvider
    extends
        $FunctionalProvider<
          RecipeRepository,
          RecipeRepository,
          RecipeRepository
        >
    with $Provider<RecipeRepository> {
  RecipeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecipeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecipeRepository create(Ref ref) {
    return recipeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeRepository>(value),
    );
  }
}

String _$recipeRepositoryHash() => r'bf804706006f4fff734de390bf228dcff9c84af0';

@ProviderFor(planRepository)
final planRepositoryProvider = PlanRepositoryProvider._();

final class PlanRepositoryProvider
    extends $FunctionalProvider<PlanRepository, PlanRepository, PlanRepository>
    with $Provider<PlanRepository> {
  PlanRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlanRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanRepository create(Ref ref) {
    return planRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanRepository>(value),
    );
  }
}

String _$planRepositoryHash() => r'76b2bc11bdd4e75648a6199305d5e2e1bf97d7b6';

@ProviderFor(shoppingRepository)
final shoppingRepositoryProvider = ShoppingRepositoryProvider._();

final class ShoppingRepositoryProvider
    extends
        $FunctionalProvider<
          ShoppingRepository,
          ShoppingRepository,
          ShoppingRepository
        >
    with $Provider<ShoppingRepository> {
  ShoppingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShoppingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShoppingRepository create(Ref ref) {
    return shoppingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingRepository>(value),
    );
  }
}

String _$shoppingRepositoryHash() =>
    r'fb7aae6d7196d183b09ab5681360e7b038e1206a';

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'0eda22c9c7a5e68c8661bf58b528d73264ef9a19';

/// Today's date from the injected clock (PLAN-13).

@ProviderFor(today)
final todayProvider = TodayProvider._();

/// Today's date from the injected clock (PLAN-13).

final class TodayProvider
    extends $FunctionalProvider<CalendarDate, CalendarDate, CalendarDate>
    with $Provider<CalendarDate> {
  /// Today's date from the injected clock (PLAN-13).
  TodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayHash();

  @$internal
  @override
  $ProviderElement<CalendarDate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CalendarDate create(Ref ref) {
    return today(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarDate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarDate>(value),
    );
  }
}

String _$todayHash() => r'677702840b37fd29639106957cdad9aed2301d31';

@ProviderFor(currentWeek)
final currentWeekProvider = CurrentWeekProvider._();

final class CurrentWeekProvider extends $FunctionalProvider<Week, Week, Week>
    with $Provider<Week> {
  CurrentWeekProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentWeekProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentWeekHash();

  @$internal
  @override
  $ProviderElement<Week> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Week create(Ref ref) {
    return currentWeek(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Week value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Week>(value),
    );
  }
}

String _$currentWeekHash() => r'0982603595c802af977a73c1656460c8eedacf82';

@ProviderFor(weekPlan)
final weekPlanProvider = WeekPlanFamily._();

final class WeekPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<SlotId, List<SlotItem>>>,
          Map<SlotId, List<SlotItem>>,
          Stream<Map<SlotId, List<SlotItem>>>
        >
    with
        $FutureModifier<Map<SlotId, List<SlotItem>>>,
        $StreamProvider<Map<SlotId, List<SlotItem>>> {
  WeekPlanProvider._({
    required WeekPlanFamily super.from,
    required Week super.argument,
  }) : super(
         retry: null,
         name: r'weekPlanProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$weekPlanHash();

  @override
  String toString() {
    return r'weekPlanProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<SlotId, List<SlotItem>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<SlotId, List<SlotItem>>> create(Ref ref) {
    final argument = this.argument as Week;
    return weekPlan(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WeekPlanProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$weekPlanHash() => r'd32167c40cd3736a1b7ba5488213cd8a090074a3';

final class WeekPlanFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<SlotId, List<SlotItem>>>, Week> {
  WeekPlanFamily._()
    : super(
        retry: null,
        name: r'weekPlanProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WeekPlanProvider call(Week week) =>
      WeekPlanProvider._(argument: week, from: this);

  @override
  String toString() => r'weekPlanProvider';
}

/// Default servings for new recipe items (PLAN-12, PLAN-18).

@ProviderFor(defaultServings)
final defaultServingsProvider = DefaultServingsProvider._();

/// Default servings for new recipe items (PLAN-12, PLAN-18).

final class DefaultServingsProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  /// Default servings for new recipe items (PLAN-12, PLAN-18).
  DefaultServingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'defaultServingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$defaultServingsHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return defaultServings(ref);
  }
}

String _$defaultServingsHash() => r'30ef17047341ae31143998b5368edd975f4950bf';

@ProviderFor(slotSuggestions)
final slotSuggestionsProvider = SlotSuggestionsFamily._();

final class SlotSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Suggestion>>,
          List<Suggestion>,
          FutureOr<List<Suggestion>>
        >
    with $FutureModifier<List<Suggestion>>, $FutureProvider<List<Suggestion>> {
  SlotSuggestionsProvider._({
    required SlotSuggestionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'slotSuggestionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$slotSuggestionsHash();

  @override
  String toString() {
    return r'slotSuggestionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Suggestion>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Suggestion>> create(Ref ref) {
    final argument = this.argument as String;
    return slotSuggestions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SlotSuggestionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$slotSuggestionsHash() => r'00cef6b72501da8c4904ae49c02309b5626c37f8';

final class SlotSuggestionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Suggestion>>, String> {
  SlotSuggestionsFamily._()
    : super(
        retry: null,
        name: r'slotSuggestionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SlotSuggestionsProvider call(String query) =>
      SlotSuggestionsProvider._(argument: query, from: this);

  @override
  String toString() => r'slotSuggestionsProvider';
}

@ProviderFor(recipeList)
final recipeListProvider = RecipeListFamily._();

final class RecipeListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecipeSummary>>,
          List<RecipeSummary>,
          Stream<List<RecipeSummary>>
        >
    with
        $FutureModifier<List<RecipeSummary>>,
        $StreamProvider<List<RecipeSummary>> {
  RecipeListProvider._({
    required RecipeListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recipeListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeListHash();

  @override
  String toString() {
    return r'recipeListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<RecipeSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<RecipeSummary>> create(Ref ref) {
    final argument = this.argument as String;
    return recipeList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeListHash() => r'ed2b1578a5e12f822abd2f72b67117cc3540a46c';

final class RecipeListFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<RecipeSummary>>, String> {
  RecipeListFamily._()
    : super(
        retry: null,
        name: r'recipeListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RecipeListProvider call(String query) =>
      RecipeListProvider._(argument: query, from: this);

  @override
  String toString() => r'recipeListProvider';
}

/// Recipe book list filtered by title and tags (RCP-9). [tagKeys] is the
/// sorted, `|`-joined set of selected tag keys (a value type for the family).

@ProviderFor(filteredRecipes)
final filteredRecipesProvider = FilteredRecipesFamily._();

/// Recipe book list filtered by title and tags (RCP-9). [tagKeys] is the
/// sorted, `|`-joined set of selected tag keys (a value type for the family).

final class FilteredRecipesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecipeSummary>>,
          List<RecipeSummary>,
          Stream<List<RecipeSummary>>
        >
    with
        $FutureModifier<List<RecipeSummary>>,
        $StreamProvider<List<RecipeSummary>> {
  /// Recipe book list filtered by title and tags (RCP-9). [tagKeys] is the
  /// sorted, `|`-joined set of selected tag keys (a value type for the family).
  FilteredRecipesProvider._({
    required FilteredRecipesFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'filteredRecipesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredRecipesHash();

  @override
  String toString() {
    return r'filteredRecipesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<RecipeSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<RecipeSummary>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return filteredRecipes(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredRecipesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredRecipesHash() => r'c9daf07b103ec7c90fd36130c84b55d5879dba17';

/// Recipe book list filtered by title and tags (RCP-9). [tagKeys] is the
/// sorted, `|`-joined set of selected tag keys (a value type for the family).

final class FilteredRecipesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<RecipeSummary>>,
          (String, String)
        > {
  FilteredRecipesFamily._()
    : super(
        retry: null,
        name: r'filteredRecipesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Recipe book list filtered by title and tags (RCP-9). [tagKeys] is the
  /// sorted, `|`-joined set of selected tag keys (a value type for the family).

  FilteredRecipesProvider call(String query, String tagKeys) =>
      FilteredRecipesProvider._(argument: (query, tagKeys), from: this);

  @override
  String toString() => r'filteredRecipesProvider';
}

@ProviderFor(recipeTags)
final recipeTagsProvider = RecipeTagsProvider._();

final class RecipeTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  RecipeTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeTagsHash();

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    return recipeTags(ref);
  }
}

String _$recipeTagsHash() => r'bd4551a479fbc582b6b5bbbc9fb38ff935af8656';

@ProviderFor(recipeIndex)
final recipeIndexProvider = RecipeIndexProvider._();

final class RecipeIndexProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, RecipeSummary>>,
          Map<int, RecipeSummary>,
          FutureOr<Map<int, RecipeSummary>>
        >
    with
        $FutureModifier<Map<int, RecipeSummary>>,
        $FutureProvider<Map<int, RecipeSummary>> {
  RecipeIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeIndexHash();

  @$internal
  @override
  $FutureProviderElement<Map<int, RecipeSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<int, RecipeSummary>> create(Ref ref) {
    return recipeIndex(ref);
  }
}

String _$recipeIndexHash() => r'feef8ead17ee4e6c41b2b9bddaaf44b327c41263';

@ProviderFor(recipe)
final recipeProvider = RecipeFamily._();

final class RecipeProvider
    extends $FunctionalProvider<AsyncValue<Recipe?>, Recipe?, Stream<Recipe?>>
    with $FutureModifier<Recipe?>, $StreamProvider<Recipe?> {
  RecipeProvider._({
    required RecipeFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'recipeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeHash();

  @override
  String toString() {
    return r'recipeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Recipe?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Recipe?> create(Ref ref) {
    final argument = this.argument as int;
    return recipe(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeHash() => r'0b618956b25c45b135dc1d17d30cfe0ac84deaa1';

final class RecipeFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Recipe?>, int> {
  RecipeFamily._()
    : super(
        retry: null,
        name: r'recipeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RecipeProvider call(int id) => RecipeProvider._(argument: id, from: this);

  @override
  String toString() => r'recipeProvider';
}

@ProviderFor(manualItems)
final manualItemsProvider = ManualItemsFamily._();

final class ManualItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ManualItem>>,
          List<ManualItem>,
          Stream<List<ManualItem>>
        >
    with $FutureModifier<List<ManualItem>>, $StreamProvider<List<ManualItem>> {
  ManualItemsProvider._({
    required ManualItemsFamily super.from,
    required Week super.argument,
  }) : super(
         retry: null,
         name: r'manualItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$manualItemsHash();

  @override
  String toString() {
    return r'manualItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ManualItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ManualItem>> create(Ref ref) {
    final argument = this.argument as Week;
    return manualItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ManualItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$manualItemsHash() => r'91570b5469b413ceefa33e81509e49356382a124';

final class ManualItemsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ManualItem>>, Week> {
  ManualItemsFamily._()
    : super(
        retry: null,
        name: r'manualItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ManualItemsProvider call(Week week) =>
      ManualItemsProvider._(argument: week, from: this);

  @override
  String toString() => r'manualItemsProvider';
}

@ProviderFor(shoppingChecks)
final shoppingChecksProvider = ShoppingChecksFamily._();

final class ShoppingChecksProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, double?>>,
          Map<String, double?>,
          Stream<Map<String, double?>>
        >
    with
        $FutureModifier<Map<String, double?>>,
        $StreamProvider<Map<String, double?>> {
  ShoppingChecksProvider._({
    required ShoppingChecksFamily super.from,
    required Week super.argument,
  }) : super(
         retry: null,
         name: r'shoppingChecksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shoppingChecksHash();

  @override
  String toString() {
    return r'shoppingChecksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, double?>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, double?>> create(Ref ref) {
    final argument = this.argument as Week;
    return shoppingChecks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingChecksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shoppingChecksHash() => r'fdb6bc629af15438e9053da71e5f360527ec90b4';

final class ShoppingChecksFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, double?>>, Week> {
  ShoppingChecksFamily._()
    : super(
        retry: null,
        name: r'shoppingChecksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShoppingChecksProvider call(Week week) =>
      ShoppingChecksProvider._(argument: week, from: this);

  @override
  String toString() => r'shoppingChecksProvider';
}

@ProviderFor(ingredientAliases)
final ingredientAliasesProvider = IngredientAliasesProvider._();

final class IngredientAliasesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          Stream<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $StreamProvider<Map<String, String>> {
  IngredientAliasesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ingredientAliasesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ingredientAliasesHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, String>> create(Ref ref) {
    return ingredientAliases(ref);
  }
}

String _$ingredientAliasesHash() => r'b26e756e77657ebc853c621fe4fe0a3a832467e8';

@ProviderFor(sectionOverrides)
final sectionOverridesProvider = SectionOverridesProvider._();

final class SectionOverridesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, StoreSection>>,
          Map<String, StoreSection>,
          Stream<Map<String, StoreSection>>
        >
    with
        $FutureModifier<Map<String, StoreSection>>,
        $StreamProvider<Map<String, StoreSection>> {
  SectionOverridesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sectionOverridesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sectionOverridesHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, StoreSection>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, StoreSection>> create(Ref ref) {
    return sectionOverrides(ref);
  }
}

String _$sectionOverridesHash() => r'3180ebd390320e694cf85d264a88f71fa7796a0b';

/// Recipe-derived entries, recomputed whenever the plan, recipes or aliases
/// change (SHOP-1..4, SHOP-7, SHOP-9).

@ProviderFor(shoppingEntries)
final shoppingEntriesProvider = ShoppingEntriesFamily._();

/// Recipe-derived entries, recomputed whenever the plan, recipes or aliases
/// change (SHOP-1..4, SHOP-7, SHOP-9).

final class ShoppingEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingEntry>>,
          List<ShoppingEntry>,
          FutureOr<List<ShoppingEntry>>
        >
    with
        $FutureModifier<List<ShoppingEntry>>,
        $FutureProvider<List<ShoppingEntry>> {
  /// Recipe-derived entries, recomputed whenever the plan, recipes or aliases
  /// change (SHOP-1..4, SHOP-7, SHOP-9).
  ShoppingEntriesProvider._({
    required ShoppingEntriesFamily super.from,
    required Week super.argument,
  }) : super(
         retry: null,
         name: r'shoppingEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shoppingEntriesHash();

  @override
  String toString() {
    return r'shoppingEntriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ShoppingEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ShoppingEntry>> create(Ref ref) {
    final argument = this.argument as Week;
    return shoppingEntries(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shoppingEntriesHash() => r'7d1888ba25159a74bb18c40e90ea26c7f3d464e5';

/// Recipe-derived entries, recomputed whenever the plan, recipes or aliases
/// change (SHOP-1..4, SHOP-7, SHOP-9).

final class ShoppingEntriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ShoppingEntry>>, Week> {
  ShoppingEntriesFamily._()
    : super(
        retry: null,
        name: r'shoppingEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Recipe-derived entries, recomputed whenever the plan, recipes or aliases
  /// change (SHOP-1..4, SHOP-7, SHOP-9).

  ShoppingEntriesProvider call(Week week) =>
      ShoppingEntriesProvider._(argument: week, from: this);

  @override
  String toString() => r'shoppingEntriesProvider';
}

@ProviderFor(shoppingList)
final shoppingListProvider = ShoppingListFamily._();

final class ShoppingListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingRow>>,
          List<ShoppingRow>,
          FutureOr<List<ShoppingRow>>
        >
    with
        $FutureModifier<List<ShoppingRow>>,
        $FutureProvider<List<ShoppingRow>> {
  ShoppingListProvider._({
    required ShoppingListFamily super.from,
    required Week super.argument,
  }) : super(
         retry: null,
         name: r'shoppingListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shoppingListHash();

  @override
  String toString() {
    return r'shoppingListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ShoppingRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ShoppingRow>> create(Ref ref) {
    final argument = this.argument as Week;
    return shoppingList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shoppingListHash() => r'16fc2034dc0a074ef176a232740f9bb9e5f68d75';

final class ShoppingListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ShoppingRow>>, Week> {
  ShoppingListFamily._()
    : super(
        retry: null,
        name: r'shoppingListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShoppingListProvider call(Week week) =>
      ShoppingListProvider._(argument: week, from: this);

  @override
  String toString() => r'shoppingListProvider';
}

@ProviderFor(httpClient)
final httpClientProvider = HttpClientProvider._();

final class HttpClientProvider
    extends $FunctionalProvider<HttpClient, HttpClient, HttpClient>
    with $Provider<HttpClient> {
  HttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'httpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$httpClientHash();

  @$internal
  @override
  $ProviderElement<HttpClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HttpClient create(Ref ref) {
    return httpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HttpClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HttpClient>(value),
    );
  }
}

String _$httpClientHash() => r'e2719afdda83e65abbababec0d9a8b6f3dc6bc57';

@ProviderFor(thumbnailer)
final thumbnailerProvider = ThumbnailerProvider._();

final class ThumbnailerProvider
    extends $FunctionalProvider<Thumbnailer, Thumbnailer, Thumbnailer>
    with $Provider<Thumbnailer> {
  ThumbnailerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'thumbnailerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$thumbnailerHash();

  @$internal
  @override
  $ProviderElement<Thumbnailer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Thumbnailer create(Ref ref) {
    return thumbnailer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Thumbnailer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Thumbnailer>(value),
    );
  }
}

String _$thumbnailerHash() => r'06a53b260a8a8b149117a6c6fd2762c6925d0a58';

@ProviderFor(recipeImporter)
final recipeImporterProvider = RecipeImporterProvider._();

final class RecipeImporterProvider
    extends $FunctionalProvider<RecipeImporter, RecipeImporter, RecipeImporter>
    with $Provider<RecipeImporter> {
  RecipeImporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeImporterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeImporterHash();

  @$internal
  @override
  $ProviderElement<RecipeImporter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecipeImporter create(Ref ref) {
    return recipeImporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeImporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeImporter>(value),
    );
  }
}

String _$recipeImporterHash() => r'3f118fbee21fabea4972f276e740d2c6691b7fc7';

@ProviderFor(shareIntentSource)
final shareIntentSourceProvider = ShareIntentSourceProvider._();

final class ShareIntentSourceProvider
    extends
        $FunctionalProvider<
          ShareIntentSource,
          ShareIntentSource,
          ShareIntentSource
        >
    with $Provider<ShareIntentSource> {
  ShareIntentSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareIntentSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareIntentSourceHash();

  @$internal
  @override
  $ProviderElement<ShareIntentSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShareIntentSource create(Ref ref) {
    return shareIntentSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareIntentSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareIntentSource>(value),
    );
  }
}

String _$shareIntentSourceHash() => r'0d223ef852e9786315c9010c48015cda844f75c7';

@ProviderFor(backupAccount)
final backupAccountProvider = BackupAccountProvider._();

final class BackupAccountProvider
    extends $FunctionalProvider<BackupAccount, BackupAccount, BackupAccount>
    with $Provider<BackupAccount> {
  BackupAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupAccountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupAccountHash();

  @$internal
  @override
  $ProviderElement<BackupAccount> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupAccount create(Ref ref) {
    return backupAccount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupAccount value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupAccount>(value),
    );
  }
}

String _$backupAccountHash() => r'75e21394b2d5d5e821a6130dd8a5e01dd83871b9';

@ProviderFor(backgroundScheduler)
final backgroundSchedulerProvider = BackgroundSchedulerProvider._();

final class BackgroundSchedulerProvider
    extends
        $FunctionalProvider<
          BackgroundScheduler?,
          BackgroundScheduler?,
          BackgroundScheduler?
        >
    with $Provider<BackgroundScheduler?> {
  BackgroundSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundSchedulerHash();

  @$internal
  @override
  $ProviderElement<BackgroundScheduler?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackgroundScheduler? create(Ref ref) {
    return backgroundScheduler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundScheduler? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundScheduler?>(value),
    );
  }
}

String _$backgroundSchedulerHash() =>
    r'3d96872e003d46df8abc4493b3052a80632f2977';

@ProviderFor(backupService)
final backupServiceProvider = BackupServiceProvider._();

final class BackupServiceProvider
    extends $FunctionalProvider<BackupService, BackupService, BackupService>
    with $Provider<BackupService> {
  BackupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupServiceHash();

  @$internal
  @override
  $ProviderElement<BackupService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupService create(Ref ref) {
    return backupService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupService>(value),
    );
  }
}

String _$backupServiceHash() => r'74c341ff5a8bf8d03932b41d440ebc8fe58c52ce';

@ProviderFor(changeTracker)
final changeTrackerProvider = ChangeTrackerProvider._();

final class ChangeTrackerProvider
    extends $FunctionalProvider<ChangeTracker, ChangeTracker, ChangeTracker>
    with $Provider<ChangeTracker> {
  ChangeTrackerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'changeTrackerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changeTrackerHash();

  @$internal
  @override
  $ProviderElement<ChangeTracker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChangeTracker create(Ref ref) {
    return changeTracker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChangeTracker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChangeTracker>(value),
    );
  }
}

String _$changeTrackerHash() => r'fe5e6514ba206d84561b3b09ccf7d3767df6aba2';

@ProviderFor(setting)
final settingProvider = SettingFamily._();

final class SettingProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  SettingProvider._({
    required SettingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'settingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$settingHash();

  @override
  String toString() {
    return r'settingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    final argument = this.argument as String;
    return setting(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SettingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$settingHash() => r'562a165a5b76dde75a6ac3e5f7641b02cab14334';

final class SettingFamily extends $Family
    with $FunctionalFamilyOverride<Stream<String?>, String> {
  SettingFamily._()
    : super(
        retry: null,
        name: r'settingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SettingProvider call(String key) =>
      SettingProvider._(argument: key, from: this);

  @override
  String toString() => r'settingProvider';
}

@ProviderFor(backupController)
final backupControllerProvider = BackupControllerProvider._();

final class BackupControllerProvider
    extends
        $FunctionalProvider<
          BackupController,
          BackupController,
          BackupController
        >
    with $Provider<BackupController> {
  BackupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupControllerHash();

  @$internal
  @override
  $ProviderElement<BackupController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupController create(Ref ref) {
    return backupController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupController>(value),
    );
  }
}

String _$backupControllerHash() => r'2322b9acebb28b8e3b6fe4279e8b356a3c17695f';

/// First launch with an empty database (DATA-14).

@ProviderFor(needsOnboarding)
final needsOnboardingProvider = NeedsOnboardingProvider._();

/// First launch with an empty database (DATA-14).

final class NeedsOnboardingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// First launch with an empty database (DATA-14).
  NeedsOnboardingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'needsOnboardingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$needsOnboardingHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return needsOnboarding(ref);
  }
}

String _$needsOnboardingHash() => r'b6b9757db097f001842a872e2ed53c2241191dcd';
