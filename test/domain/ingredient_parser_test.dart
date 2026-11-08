import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/domain/ingredient_parser.dart';

typedef Case = (String input, double? qty, String? unit, String? name);

void main() {
  const parser = IngredientParser();

  void runCases(String group, List<Case> cases) {
    for (final (input, qty, unit, name) in cases) {
      test('$group: "$input"', () {
        final r = parser.parse(input);
        expect(
          r.quantity,
          qty == null ? isNull : closeTo(qty, 1e-9),
          reason: 'quantity',
        );
        expect(r.unit, unit, reason: 'unit');
        expect(r.name, name, reason: 'name');
      });
    }
  }

  // Covers: PARSE-1, PARSE-2
  runCases('numbers', [
    ('200 g farina', 200, 'g', 'farina'),
    ('1,5 kg patate', 1.5, 'kg', 'patate'),
    ('0.5 l latte', 0.5, 'l', 'latte'),
    ('3 uova', 3, null, 'uova'),
    ('1 cipolla', 1, null, 'cipolla'),
    ('una cipolla', 1, null, 'cipolla'),
    ('un uovo', 1, null, 'uovo'),
  ]);

  // Covers: PARSE-3
  runCases('fractions', [
    ('1/2 cipolla', 0.5, null, 'cipolla'),
    ('½ limone', 0.5, null, 'limone'),
    ('1 ½ cucchiaio di olio', 1.5, 'cucchiaio', 'olio'),
    ('1½ cucchiai di zucchero', 1.5, 'cucchiaio', 'zucchero'),
    ('1 1/2 kg di farina', 1.5, 'kg', 'farina'),
    ('¼ di cavolo', 0.25, null, 'cavolo'),
  ]);

  // Covers: PARSE-4
  runCases('ranges', [
    ('2-3 uova', 3, null, 'uova'),
    ('2 - 3 patate', 3, null, 'patate'),
    ('100–150 g di zucchero', 150, 'g', 'zucchero'),
  ]);

  // Covers: PARSE-5
  runCases('unit position', [
    ('g 200 farina', 200, 'g', 'farina'),
    ('200 g di farina', 200, 'g', 'farina'),
    ('200g farina', 200, 'g', 'farina'),
    ('200 gr di carne macinata', 200, 'g', 'carne macinata'),
    ('1 kg. di cozze', 1, 'kg', 'cozze'),
    ('3 spicchi d\'aglio', 3, 'spicchio', 'aglio'),
    ('3 spicchi d’aglio', 3, 'spicchio', 'aglio'),
    ('2 cucchiai di zucchero', 2, 'cucchiaio', 'zucchero'),
    ('1 cucchiaino di lievito', 1, 'cucchiaino', 'lievito'),
    ('1 litro di brodo vegetale', 1, 'l', 'brodo vegetale'),
    ('2 etti di prosciutto cotto', 2, 'hg', 'prosciutto cotto'),
    ('250 ml di panna fresca', 250, 'ml', 'panna fresca'),
    ('Farina 00 200 g', 200, 'g', 'Farina 00'),
    ('Spaghetti 320 g', 320, 'g', 'Spaghetti'),
    ('Uova 2', 2, null, 'Uova'),
    ('Burro 50 g (morbido)', 50, 'g', 'Burro'),
    ('200 g di burro (a temperatura ambiente)', 200, 'g', 'burro'),
    ('Farina 00', null, null, 'Farina 00'),
  ]);

  // Covers: PARSE-6
  runCases('no quantity', [
    ('Sale q.b.', null, null, 'Sale'),
    ('sale qb', null, null, 'sale'),
    ('q.b. pepe nero', null, null, 'pepe nero'),
    ('un pizzico di sale', null, null, 'sale'),
    ('Pepe nero a piacere', null, null, 'Pepe nero'),
    ('Olio extravergine d\'oliva', null, null, 'Olio extravergine d\'oliva'),
    ('un filo d\'olio', null, null, 'olio'),
    ('', null, null, null),
    ('   ', null, null, null),
  ]);
}
