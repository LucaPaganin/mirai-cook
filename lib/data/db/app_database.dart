import 'package:drift/drift.dart';

import 'app_database.steps.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Recipes,
    IngredientLines,
    SlotItems,
    ShoppingChecks,
    ManualShoppingItems,
    IngredientAliases,
    SectionOverrides,
    Settings,
    Tags,
    RecipeTags,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      // v2: recipe tags (RCP-7).
      from1To2: (m, schema) async {
        await m.createTable(schema.tags);
        await m.createTable(schema.recipeTags);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
