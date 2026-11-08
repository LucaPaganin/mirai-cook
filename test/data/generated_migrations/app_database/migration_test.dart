// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:mirai_cook/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // Covers: DATA-9
  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  // Covers: DATA-9, RCP-7
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    // TODO: Fill these lists
    final oldRecipesData = <v1.RecipesData>[
      const v1.RecipesData(
        id: 1,
        title: 'Carbonara',
        servings: 4,
        steps: '["Cuoci la pasta"]',
        sourceUrl: 'https://example.com/c',
      ),
    ];
    final expectedNewRecipesData = <v2.RecipesData>[
      const v2.RecipesData(
        id: 1,
        title: 'Carbonara',
        servings: 4,
        steps: '["Cuoci la pasta"]',
        sourceUrl: 'https://example.com/c',
      ),
    ];

    final oldIngredientLinesData = <v1.IngredientLinesData>[
      const v1.IngredientLinesData(
        id: 1,
        recipeId: 1,
        position: 0,
        original: '320 g spaghetti',
        quantity: 320,
        unit: 'g',
        name: 'spaghetti',
      ),
    ];
    final expectedNewIngredientLinesData = <v2.IngredientLinesData>[
      const v2.IngredientLinesData(
        id: 1,
        recipeId: 1,
        position: 0,
        original: '320 g spaghetti',
        quantity: 320,
        unit: 'g',
        name: 'spaghetti',
      ),
    ];

    final oldSlotItemsData = <v1.SlotItemsData>[
      const v1.SlotItemsData(
        id: 1,
        date: 20261105,
        meal: 1,
        position: 0,
        recipeId: 1,
        servings: 2,
      ),
      const v1.SlotItemsData(
        id: 2,
        date: 20261105,
        meal: 2,
        position: 0,
        freeText: 'Pizza',
      ),
    ];
    final expectedNewSlotItemsData = <v2.SlotItemsData>[
      const v2.SlotItemsData(
        id: 1,
        date: 20261105,
        meal: 1,
        position: 0,
        recipeId: 1,
        servings: 2,
      ),
      const v2.SlotItemsData(
        id: 2,
        date: 20261105,
        meal: 2,
        position: 0,
        freeText: 'Pizza',
      ),
    ];

    final oldShoppingChecksData = <v1.ShoppingChecksData>[];
    final expectedNewShoppingChecksData = <v2.ShoppingChecksData>[];

    final oldManualShoppingItemsData = <v1.ManualShoppingItemsData>[];
    final expectedNewManualShoppingItemsData = <v2.ManualShoppingItemsData>[];

    final oldIngredientAliasesData = <v1.IngredientAliasesData>[];
    final expectedNewIngredientAliasesData = <v2.IngredientAliasesData>[];

    final oldSectionOverridesData = <v1.SectionOverridesData>[];
    final expectedNewSectionOverridesData = <v2.SectionOverridesData>[];

    final oldSettingsData = <v1.SettingsData>[
      const v1.SettingsData(key: 'default_servings', value: '2'),
    ];
    final expectedNewSettingsData = <v2.SettingsData>[
      const v2.SettingsData(key: 'default_servings', value: '2'),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.recipes, oldRecipesData);
        batch.insertAll(oldDb.ingredientLines, oldIngredientLinesData);
        batch.insertAll(oldDb.slotItems, oldSlotItemsData);
        batch.insertAll(oldDb.shoppingChecks, oldShoppingChecksData);
        batch.insertAll(oldDb.manualShoppingItems, oldManualShoppingItemsData);
        batch.insertAll(oldDb.ingredientAliases, oldIngredientAliasesData);
        batch.insertAll(oldDb.sectionOverrides, oldSectionOverridesData);
        batch.insertAll(oldDb.settings, oldSettingsData);
      },
      validateItems: (newDb) async {
        expect(expectedNewRecipesData, await newDb.select(newDb.recipes).get());
        expect(
          expectedNewIngredientLinesData,
          await newDb.select(newDb.ingredientLines).get(),
        );
        expect(
          expectedNewSlotItemsData,
          await newDb.select(newDb.slotItems).get(),
        );
        expect(
          expectedNewShoppingChecksData,
          await newDb.select(newDb.shoppingChecks).get(),
        );
        expect(
          expectedNewManualShoppingItemsData,
          await newDb.select(newDb.manualShoppingItems).get(),
        );
        expect(
          expectedNewIngredientAliasesData,
          await newDb.select(newDb.ingredientAliases).get(),
        );
        expect(
          expectedNewSectionOverridesData,
          await newDb.select(newDb.sectionOverrides).get(),
        );
        expect(
          expectedNewSettingsData,
          await newDb.select(newDb.settings).get(),
        );
      },
    );
  });
}
