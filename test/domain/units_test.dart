import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/domain/name_normalizer.dart';
import 'package:mirai_cook/domain/units.dart';

void main() {
  // Covers: SHOP-11
  group('normalizeName', () {
    for (final (input, expected) in [
      ('Farina 00', 'farina 00'),
      ('  Pomodori   pelati ', 'pomodori pelati'),
      ('Caffè', 'caffe'),
      ('Olio d’oliva', "olio d'oliva"),
      ('PERE', 'pere'),
      ('pomodori', 'pomodori'), // no plural folding
    ]) {
      test('"$input" -> "$expected"', () {
        expect(normalizeName(input), expected);
      });
    }
  });

  // Covers: SHOP-10
  group('sumAmounts', () {
    for (final (amounts, expected) in [
      ([const Amount(200, 'g'), const Amount(300, 'g')], const Amount(500, 'g')),
      ([const Amount(200, 'g'), const Amount(1, 'kg')], const Amount(1.2, 'kg')),
      ([const Amount(500, 'g'), const Amount(0.4, 'kg')], const Amount(900, 'g')),
      ([const Amount(2, 'hg'), const Amount(100, 'g')], const Amount(300, 'g')),
      ([const Amount(500, 'ml'), const Amount(1, 'l')], const Amount(1.5, 'l')),
      ([const Amount(2, 'cucchiaio'), const Amount(3, 'cucchiaio')],
          const Amount(5, 'cucchiaio')),
      ([const Amount(1, 'cucchiaio'), const Amount(1, 'cucchiaino')],
          const Amount(20, 'ml')),
      ([const Amount(2, 'dl'), const Amount(5, 'cl')], const Amount(250, 'ml')),
      ([const Amount(2, 'spicchio'), const Amount(1, 'spicchio')],
          const Amount(3, 'spicchio')),
      ([const Amount(2, null), const Amount(3, null)], const Amount(5, null)),
    ]) {
      test('$amounts -> $expected', () {
        expect(sumAmounts(amounts), expected);
      });
    }
  });

  // Covers: SHOP-10
  test('lookup resolves spelling variants', () {
    expect(Units.lookup('Grammi')!.symbol, 'g');
    expect(Units.lookup('kg.')!.symbol, 'kg');
    expect(Units.lookup('cucchiai')!.symbol, 'cucchiaio');
    expect(Units.lookup('uova'), isNull);
    expect(Units.lookup('spicchi')!.isConvertible, isFalse);
  });
}
