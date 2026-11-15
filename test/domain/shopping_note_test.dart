import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/domain/calendar.dart';
import 'package:mirai_cook/domain/shopping.dart';
import 'package:mirai_cook/domain/shopping_note.dart';
import 'package:mirai_cook/domain/store_section.dart';
import 'package:mirai_cook/domain/units.dart';

ShoppingRow row(
  String label, {
  Amount? amount,
  bool checked = false,
  StoreSection section = StoreSection.pantry,
}) => ShoppingRow(
  key: label,
  label: label,
  name: label,
  amount: amount,
  section: section,
  checked: checked,
);

void main() {
  final week = Week.containing(const CalendarDate(2026, 11, 5));

  // Covers: EXP-1
  test('title names the week, one line per item with its quantity', () {
    final note = buildShoppingNote(week, [
      row(
        'zucchine',
        amount: const Amount(2, null),
        section: StoreSection.produce,
      ),
      row('farina', amount: const Amount(1.5, 'kg')),
      row('uova', amount: const Amount(3, null), section: StoreSection.dairy),
      row('Sale q.b.'),
      row('cucchiaio di olio', amount: const Amount(2, 'cucchiaio')),
    ]);
    expect(note.title, 'Spesa 2 nov – 8 nov');
    expect(note.lines, [
      'zucchine 2',
      'farina 1,5 kg',
      'uova 3',
      'Sale q.b.',
      'cucchiaio di olio 2 cucchiai',
    ]);
    expect(note.text, note.lines.join('\n'));
  });

  // Covers: EXP-1
  test('keeps the order of the rows (store sections)', () {
    final rows = [
      row('mele', section: StoreSection.produce),
      row('latte', section: StoreSection.dairy),
      row('pasta'),
    ];
    expect(buildShoppingNote(week, rows).lines, ['mele', 'latte', 'pasta']);
  });

  // Covers: EXP-2
  test('leaves out checked items', () {
    final note = buildShoppingNote(week, [
      row('farina', checked: true),
      row('uova'),
    ]);
    expect(note.lines, ['uova']);
    expect(
      buildShoppingNote(week, [row('farina', checked: true)]).isEmpty,
      isTrue,
    );
  });
}
