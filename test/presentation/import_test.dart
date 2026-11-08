import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/data/db/drift_repositories.dart';
import 'package:mirai_cook/data/http_client.dart';
import 'package:mirai_cook/domain/recipe.dart';

import 'helpers.dart';

const url = 'https://example.com/ricette/norma';

HttpResponse page(String fixture) => HttpResponse(
  200,
  utf8.encode(File('test/fixtures/$fixture').readAsStringSync()),
);

Future<List<RecipeSummary>> savedRecipes(
  WidgetTester tester,
  TestApp app,
) async => (await tester.runAsync(
  () => DriftRecipeRepository(app.db).watchAll().first,
))!;

void main() {
  // Covers: IMP-1, IMP-8
  appTest('a shared URL opens the prefilled editor; saving persists', (
    tester,
    app,
  ) async {
    app.http.responses[url] = page('jsonld_simple.html');
    app.share.controller.add('Pasta alla Norma $url');
    await settle(tester);
    expect(find.text('Nuova ricetta'), findsOneWidget);
    expect(find.text('Pasta alla Norma'), findsOneWidget);
    expect(await savedRecipes(tester, app), isEmpty);

    await tester.tap(find.byKey(const Key('save-recipe')));
    await settle(tester);
    final saved = await savedRecipes(tester, app);
    expect(saved.single.title, 'Pasta alla Norma');
  });

  // Covers: IMP-8
  appTest('leaving the editor without saving discards the import', (
    tester,
    app,
  ) async {
    app.http.responses[url] = page('jsonld_simple.html');
    app.share.controller.add(url);
    await settle(tester);
    expect(find.text("Pasta alla Norma"), findsOneWidget);
    await tester.binding.handlePopRoute(); // Android back
    await settle(tester);
    expect(await savedRecipes(tester, app), isEmpty);
  });

  // Covers: IMP-2, IMP-5
  appTest('pasting a URL without JSON-LD opens editor with page title', (
    tester,
    app,
  ) async {
    app.http.responses[url] = page('no_jsonld.html');
    await tester.tap(find.text('Ricette'));
    await settle(tester);
    await tester.tap(find.byTooltip('Importa da URL'));
    await settleUntilFound(tester, find.byKey(const Key('import-url')));
    await tester.enterText(find.byKey(const Key('import-url')), url);
    await tester.tap(find.text('Importa'));
    await settle(tester);
    expect(find.text('La mia cena preferita'), findsOneWidget);
    expect(find.text(url), findsOneWidget);
  });

  // Covers: IMP-6
  appTest('a fetch error offers retry and manual entry', (tester, app) async {
    app.share.controller.add(url);
    await settle(tester);
    expect(find.textContaining('HTTP 404'), findsOneWidget);
    expect(find.text(url), findsOneWidget);
    app.http.responses[url] = page('jsonld_simple.html');
    await tester.tap(find.text('Riprova'));
    await settle(tester);
    expect(find.text('Pasta alla Norma'), findsOneWidget);
  });

  // Covers: IMP-9
  appTest(
    'an already imported URL offers to open the existing recipe',
    seed: (db) => DriftRecipeRepository(db)
        .save(const Recipe(title: 'La mia Norma', servings: 4, sourceUrl: url)),
    (tester, app) async {
      app.share.controller.add(url);
      await settle(tester);
      expect(find.textContaining('La mia Norma'), findsOneWidget);
      await tester.tap(find.text('Apri'));
      await settle(tester);
      expect(find.text('• '), findsNothing);
      expect(find.byTooltip('Modifica'), findsOneWidget);
    },
  );
}
