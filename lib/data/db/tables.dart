import 'package:drift/drift.dart';

@DataClassName('RecipeRow')
class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get servings => real()();

  /// JSON-encoded list of step strings.
  TextColumn get steps => text().withDefault(const Constant('[]'))();
  TextColumn get sourceUrl => text().nullable()();
  BlobColumn get thumbnail => blob().nullable()();
}

@TableIndex(name: 'ingredient_lines_recipe', columns: {#recipeId})
@DataClassName('IngredientLineRow')
class IngredientLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId =>
      integer().references(Recipes, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get original => text()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get name => text().nullable()();
}

/// One entry of a meal slot (PLAN-3, PLAN-15). Exactly one of [freeText]
/// and [recipeId] is set.
@TableIndex(name: 'slot_items_date', columns: {#date})
@DataClassName('SlotItemRow')
class SlotItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Calendar date as yyyymmdd.
  IntColumn get date => integer()();

  /// `MealType.index`.
  IntColumn get meal => integer()();
  IntColumn get position => integer()();
  TextColumn get freeText => text().nullable()();
  IntColumn get recipeId => integer().nullable().references(Recipes, #id)();
  RealColumn get servings => real().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK ((free_text IS NULL) <> (recipe_id IS NULL))',
  ];
}

/// Checked state of recipe-derived shopping entries (SHOP-6..8).
@DataClassName('ShoppingCheckRow')
class ShoppingChecks extends Table {
  /// Monday of the week, yyyymmdd.
  IntColumn get week => integer()();
  TextColumn get entryKey => text()();

  /// Quantity in base units when checked, null for unquantified entries.
  RealColumn get checkedQuantity => real().nullable()();

  @override
  Set<Column> get primaryKey => {week, entryKey};
}

@DataClassName('ManualShoppingItemRow')
class ManualShoppingItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get week => integer()();
  TextColumn get label => text()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
}

@DataClassName('IngredientAliasRow')
class IngredientAliases extends Table {
  TextColumn get fromName => text()();
  TextColumn get toName => text()();

  @override
  Set<Column> get primaryKey => {fromName};
}

@DataClassName('SectionOverrideRow')
class SectionOverrides extends Table {
  TextColumn get name => text()();

  /// `StoreSection.index`.
  IntColumn get section => integer()();

  @override
  Set<Column> get primaryKey => {name};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
