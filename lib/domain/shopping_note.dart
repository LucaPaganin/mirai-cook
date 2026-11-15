import 'calendar.dart';
import 'italian_format.dart';
import 'shopping.dart';

/// A shopping list rendered as a plain-text note for an external list app
/// (EXP-1).
class ShoppingNote {
  const ShoppingNote({required this.title, required this.lines});

  final String title;

  /// One item per line, in store-section order.
  final List<String> lines;

  bool get isEmpty => lines.isEmpty;

  /// Note body: one item per line, so list apps can turn it into a
  /// checklist.
  String get text => lines.join('\n');
}

/// Builds the note for [week] from its shopping list [rows] (already sorted
/// by section, SHOP-13). Checked items are left out: they are already in
/// the trolley (EXP-2).
ShoppingNote buildShoppingNote(Week week, List<ShoppingRow> rows) =>
    ShoppingNote(
      title: 'Spesa ${weekRange(week)}',
      lines: [
        for (final r in rows)
          if (!r.checked)
            r.amount == null
                ? r.label
                : '${r.label} ${formatAmount(r.amount!)}',
      ],
    );
