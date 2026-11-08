import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/application/recipe_importer.dart';
import 'package:mirai_cook/data/db/app_database.dart';
import 'package:mirai_cook/data/db/drift_repositories.dart';
import 'package:mirai_cook/data/http_client.dart';
import 'package:mirai_cook/domain/recipe.dart';

import '../fakes.dart';

HttpResponse page(String fixture) => HttpResponse(
  200,
  utf8.encode(File('test/fixtures/$fixture').readAsStringSync()),
);

void main() {
  late AppDatabase db;
  late DriftRecipeRepository repo;
  late FakeHttpClient http;
  late FakeThumbnailer thumbs;
  late RecipeImporter importer;

  const url = 'https://example.com/ricette/norma';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftRecipeRepository(db);
    http = FakeHttpClient();
    thumbs = FakeThumbnailer();
    importer = RecipeImporter(http: http, recipes: repo, thumbnailer: thumbs);
  });
  tearDown(() => db.close());

  // Covers: IMP-3, IMP-4, IMP-7, IMP-8
  test(
    'builds an unsaved draft with parsed ingredients and thumbnail',
    () async {
      http.responses[url] = page('jsonld_simple.html');
      http.responses['https://example.com/img/norma.jpg'] = const HttpResponse(
        200,
        [1, 2, 3],
      );
      final result = await importer.import(url);
      final draft = (result as ImportDraft).recipe;
      expect(result.structured, isTrue);
      expect(draft.id, isNull);
      expect(draft.title, 'Pasta alla Norma');
      expect(draft.servings, 4);
      expect(draft.sourceUrl, url);
      expect(draft.thumbnail, [9, 9, 9]);
      expect(thumbs.inputs.single, [1, 2, 3]);
      expect(
        draft.ingredients.first,
        const IngredientLine(
          original: 'Rigatoni 320 g',
          quantity: 320,
          unit: 'g',
          name: 'Rigatoni',
        ),
      );
      expect(draft.steps, hasLength(3));
      expect(draft.tags, contains('Primi piatti')); // IMP-10
      expect(await repo.watchAll().first, isEmpty, reason: 'nothing saved');
    },
  );

  // Covers: IMP-1, IMP-2
  test('extracts the URL from shared text', () async {
    http.responses[url] = page('jsonld_simple.html');
    final result = await importer.import(
      'Guarda questa ricetta: Pasta alla Norma $url',
    );
    expect(result, isA<ImportDraft>());
    expect(extractUrl('vedi (https://a.it/x).'), Uri.parse('https://a.it/x'));
    expect(extractUrl('niente link'), isNull);
  });

  // Covers: IMP-5
  test('without JSON-LD the draft has only page title and URL', () async {
    http.responses[url] = page('no_jsonld.html');
    final result = await importer.import(url) as ImportDraft;
    expect(result.structured, isFalse);
    expect(result.recipe.title, 'La mia cena preferita');
    expect(result.recipe.sourceUrl, url);
    expect(result.recipe.ingredients, isEmpty);
  });

  // Covers: IMP-6
  test('fetch errors keep the URL for retry', () async {
    final notFound = await importer.import(url) as ImportFailure;
    expect(notFound.url, Uri.parse(url));
    expect(notFound.message, contains('404'));

    http.throwOnGet = const SocketException('offline');
    final offline = await importer.import(url) as ImportFailure;
    expect(offline.url, Uri.parse(url));

    final invalid = await importer.import('non è un link') as ImportFailure;
    expect(invalid.url, isNull);
  });

  // Covers: IMP-7
  test('a broken image does not break the import', () async {
    http.responses[url] = page('jsonld_simple.html');
    final result = await importer.import(url) as ImportDraft;
    expect(result.recipe.thumbnail, isNull);
  });

  // Covers: IMP-9
  test('an already imported URL is reported as duplicate', () async {
    await repo.save(const Recipe(title: 'Norma', servings: 4, sourceUrl: url));
    final result = await importer.import(url);
    expect(result, isA<ImportDuplicate>());
    expect(http.requested, isEmpty);
    http.responses[url] = page('jsonld_simple.html');
    expect(
      await importer.import(url, allowDuplicate: true),
      isA<ImportDraft>(),
    );
  });
}
