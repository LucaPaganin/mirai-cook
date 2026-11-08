import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/domain/recipe_extractor.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  const extractor = RecipeExtractor();

  // Covers: IMP-3, IMP-10
  test('extracts a plain schema.org Recipe', () {
    final r = extractor.extract(fixture('jsonld_simple.html'))!;
    expect(r.title, 'Pasta alla Norma');
    expect(r.servings, 4);
    expect(r.imageUrl, 'https://example.com/img/norma.jpg');
    expect(r.ingredients, hasLength(6));
    expect(r.ingredients.last, "Olio extravergine d'oliva q.b.");
    expect(r.tags, [
      'Primi piatti',
      'Italiana',
      'pasta',
      'melanzane',
      'Veloce',
    ]);
    expect(r.steps, [
      'Taglia le melanzane a cubetti e friggile.',
      'Prepara il sugo con i pelati.',
      'Condisci la pasta e grattugia la ricotta.',
    ]);
  });

  // Covers: IMP-3, IMP-10
  test('finds the Recipe in @graph, flattens sections, decodes entities', () {
    final r = extractor.extract(fixture('jsonld_graph.html'))!;
    expect(r.title, 'Torta di mele & cannella');
    expect(r.servings, 8);
    expect(r.imageUrl, 'https://example.com/torta-1200.jpg');
    expect(r.tags, ['Dolci', 'Torte', 'torta', 'colazione']);
    expect(r.ingredients.first, '3 uova');
    expect(r.steps, [
      'Monta le uova con lo zucchero.',
      'Aggiungi la farina e il lievito.',
      'Inforna a 180°C per 40 minuti.',
    ]);
  });

  // Covers: IMP-3
  test('handles top-level arrays, string steps, yield text, bad JSON', () {
    final r = extractor.extract(fixture('jsonld_string_steps.html'))!;
    expect(r.title, 'Minestrone');
    expect(r.servings, 6);
    expect(r.imageUrl, 'https://example.com/m.jpg');
    expect(r.steps, ['Taglia le verdure.', 'Cuoci nel brodo per 30 minuti.']);
    expect(r.tags, isEmpty);
  });

  // Covers: IMP-5
  test('returns null without a Recipe, but exposes the page title', () {
    final html = fixture('no_jsonld.html');
    expect(extractor.extract(html), isNull);
    expect(extractor.pageTitle(html), 'La mia cena preferita');
  });

  // Covers: IMP-3
  group('parseYield', () {
    for (final (input, expected) in [
      ('4', 4.0),
      (4, 4.0),
      ('4 porzioni', 4.0),
      ('Per 6 persone', 6.0),
      (['8', '8 fette'], 8.0),
      ('2-3', 3.0),
      ('qualche', null),
      (null, null),
    ]) {
      test('$input -> $expected', () {
        expect(RecipeExtractor.parseYield(input), expected);
      });
    }
  });
}
