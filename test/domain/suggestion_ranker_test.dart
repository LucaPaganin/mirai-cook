import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/domain/calendar.dart';
import 'package:mirai_cook/domain/suggestion_ranker.dart';

void main() {
  const today = CalendarDate(2026, 11, 8);
  CalendarDate daysAgo(int n) => today.addDays(-n);
  const ranker = SuggestionRanker();

  List<String> labels(List<Suggestion> s) => s.map((x) => x.label).toList();

  // Covers: PLAN-6
  test('matches word prefixes, accent and case insensitive', () {
    final c = [
      const Suggestion.recipe(1, 'Pasta al pesto', []),
      const Suggestion.recipe(2, 'Caffè latte', []),
      const Suggestion.freeText('Pizza fuori', []),
      const Suggestion.recipe(3, 'Insalata di riso', []),
    ];
    expect(labels(ranker.rank('pes', c, today)), ['Pasta al pesto']);
    expect(labels(ranker.rank('CAFFE', c, today)), ['Caffè latte']);
    expect(
      labels(ranker.rank('p', c, today)),
      unorderedEquals(['Pasta al pesto', 'Pizza fuori']),
    );
    expect(labels(ranker.rank('di ris', c, today)), ['Insalata di riso']);
    expect(ranker.rank('xyz', c, today), isEmpty);
  });

  // Covers: PLAN-6
  test('ranks by frequency', () {
    final c = [
      Suggestion.recipe(1, 'Pasta al pesto', [daysAgo(10)]),
      Suggestion.recipe(2, 'Pasta e fagioli', [daysAgo(10), daysAgo(11)]),
    ];
    expect(labels(ranker.rank('pasta', c, today)), [
      'Pasta e fagioli',
      'Pasta al pesto',
    ]);
  });

  // Covers: PLAN-6
  test('recent use beats old frequent use', () {
    final c = [
      Suggestion.recipe(1, 'Pasta al pesto', [
        daysAgo(200),
        daysAgo(210),
        daysAgo(220),
      ]),
      Suggestion.recipe(2, 'Pasta e fagioli', [daysAgo(2)]),
    ];
    expect(labels(ranker.rank('pasta', c, today)), [
      'Pasta e fagioli',
      'Pasta al pesto',
    ]);
  });

  // Covers: PLAN-6
  test('ties: recipes first, then alphabetical; empty query lists all', () {
    final c = [
      const Suggestion.freeText('Avanzi', []),
      const Suggestion.recipe(1, 'Zuppa', []),
      const Suggestion.recipe(2, 'Bistecca', []),
    ];
    expect(labels(ranker.rank('', c, today)), ['Bistecca', 'Zuppa', 'Avanzi']);
  });

  // Covers: PLAN-6
  test('free text equal to a recipe title is folded into the recipe', () {
    final c = [
      const Suggestion.recipe(1, 'Lasagna', []),
      Suggestion.freeText('lasagna', [daysAgo(1)]),
    ];
    final r = ranker.rank('las', c, today);
    expect(r, hasLength(1));
    expect(r.single.recipeId, 1);
  });

  // Covers: PLAN-6
  test('future planned uses count as today', () {
    expect(ranker.score([today.addDays(5)], today), closeTo(1, 1e-9));
    expect(ranker.score([daysAgo(30)], today), closeTo(0.5, 1e-9));
  });
}
