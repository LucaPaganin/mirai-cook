import '../domain/calendar.dart';
import '../domain/shopping.dart';
import '../domain/shopping_note.dart';
import 'ports/shopping_list_exporter.dart';

/// Use case: export a week's shopping list to an external app (EXP-1..3).
class ShoppingListExport {
  const ShoppingListExport(this.exporter);

  final ShoppingListExporter exporter;

  Future<ExportResult> export(Week week, List<ShoppingRow> rows) async {
    final note = buildShoppingNote(week, rows);
    if (note.isEmpty) return const ExportNothingToDo();
    try {
      return await exporter.export(note);
    } on Object catch (e) {
      return ExportFailed('$e');
    }
  }
}
