import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/application/ports/shopping_list_exporter.dart';
import 'package:mirai_cook/application/shopping_export.dart';
import 'package:mirai_cook/domain/calendar.dart';
import 'package:mirai_cook/domain/shopping.dart';
import 'package:mirai_cook/domain/shopping_note.dart';
import 'package:mirai_cook/domain/store_section.dart';

import '../fakes.dart';

class ThrowingExporter implements ShoppingListExporter {
  @override
  Future<ExportResult> export(ShoppingNote note) async =>
      throw StateError('boom');
}

void main() {
  final week = Week.containing(const CalendarDate(2026, 11, 5));
  const uova = ShoppingRow(
    key: 'uova',
    label: 'uova',
    name: 'uova',
    section: StoreSection.dairy,
    checked: false,
  );

  // Covers: EXP-1
  test('hands the note to the exporter and returns its result', () async {
    final exporter = FakeShoppingListExporter(const ExportUnavailable());
    final result = await ShoppingListExport(exporter).export(week, [uova]);
    expect(result, isA<ExportUnavailable>());
    expect(exporter.exported.single.lines, ['uova']);
  });

  // Covers: EXP-2
  test('does not call the exporter when nothing is left to buy', () async {
    final exporter = FakeShoppingListExporter();
    final result = await ShoppingListExport(exporter).export(week, const [
      ShoppingRow(
        key: 'uova',
        label: 'uova',
        name: 'uova',
        section: StoreSection.dairy,
        checked: true,
      ),
    ]);
    expect(result, isA<ExportNothingToDo>());
    expect(exporter.exported, isEmpty);
  });

  test('turns exporter errors into a failure', () async {
    final result = await ShoppingListExport(ThrowingExporter())
        .export(week, [uova]);
    expect(result, isA<ExportFailed>());
  });
}
