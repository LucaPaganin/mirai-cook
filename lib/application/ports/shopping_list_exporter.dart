import '../../domain/shopping_note.dart';

sealed class ExportResult {
  const ExportResult();
}

/// The note was handed to the destination app.
class ExportDone extends ExportResult {
  const ExportDone();
}

/// The destination is not available on this device (e.g. the app is not
/// installed, EXP-3).
class ExportUnavailable extends ExportResult {
  const ExportUnavailable();
}

class ExportFailed extends ExportResult {
  const ExportFailed(this.message);
  final String message;
}

/// Nothing left to buy: no export was attempted (EXP-2). Produced by the
/// use case, never by an exporter.
class ExportNothingToDo extends ExportResult {
  const ExportNothingToDo();
}

/// Sends a shopping list to an external list app (EXP-1). One adapter per
/// destination: Google Keep, the system share sheet, …
abstract interface class ShoppingListExporter {
  Future<ExportResult> export(ShoppingNote note);
}
