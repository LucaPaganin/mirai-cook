import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/domain/tags.dart';

void main() {
  // Covers: RCP-7
  group('cleanTags', () {
    for (final (input, expected) in [
      (['Veloce', 'veloce ', 'VELOCE'], ['Veloce']),
      (['  Primi   piatti '], ['Primi piatti']),
      (['Caffè', 'caffe'], ['Caffè']),
      (['', '  ', 'forno'], ['forno']),
      (['#vegetariano'], ['vegetariano']),
    ]) {
      test('$input -> $expected', () {
        expect(cleanTags(input), expected);
      });
    }
  });

  // Covers: RCP-8
  test('suggestTags matches word prefixes and skips chosen tags', () {
    const known = ['Veloce', 'Vegetariano', 'Primi piatti', 'Forno'];
    expect(suggestTags('ve', known, const []), ['Vegetariano', 'Veloce']);
    expect(suggestTags('piat', known, const []), ['Primi piatti']);
    expect(suggestTags('ve', known, const ['veloce']), ['Vegetariano']);
    expect(suggestTags('', known, const []), isEmpty);
  });
}
