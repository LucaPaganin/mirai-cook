import 'name_normalizer.dart';
import 'recipe.dart';
import 'store_section.dart';
import 'units.dart';

/// A recipe used in a slot item with its servings.
class PlannedRecipe {
  const PlannedRecipe(this.recipe, this.servings);

  final Recipe recipe;
  final double servings;
}

/// A recipe-derived shopping list entry.
class ShoppingEntry {
  const ShoppingEntry({
    required this.key,
    required this.name,
    required this.label,
    this.amount,
  });

  /// Stable identity used to persist the checked state (SHOP-7).
  final String key;

  /// Normalized (alias-resolved) ingredient name.
  final String name;

  /// What the user sees: the name for merged entries, the original line
  /// for entries without quantity (SHOP-4).
  final String label;
  final Amount? amount;
}

/// Follows alias chains (SHOP-12), stopping on cycles.
String resolveAlias(String name, Map<String, String> aliases) {
  var current = name;
  final seen = <String>{current};
  while (true) {
    final next = aliases[current];
    if (next == null || !seen.add(next)) return current;
    current = next;
  }
}

/// Collects, scales and merges ingredients (SHOP-1..4, SHOP-10..12).
class ShoppingAggregator {
  const ShoppingAggregator({this.aliases = const {}});

  final Map<String, String> aliases;

  List<ShoppingEntry> aggregate(List<PlannedRecipe> planned) {
    final amounts = <String, List<Amount>>{};
    final names = <String, String>{};
    final unquantified = <String, ShoppingEntry>{};

    for (final p in planned) {
      final recipeServings = p.recipe.servings > 0 ? p.recipe.servings : 1;
      final factor = p.servings / recipeServings;
      for (final ing in p.recipe.ingredients) {
        final q = ing.quantity;
        final rawName = ing.name;
        if (q == null || rawName == null) {
          // SHOP-4: listed as the original line. Identical lines are shown
          // once; no quantities are combined.
          final key = 'line:${normalizeName(ing.original)}';
          unquantified.putIfAbsent(
            key,
            () => ShoppingEntry(
              key: key,
              name: resolveAlias(
                  normalizeName(rawName ?? ing.original), aliases),
              label: ing.original,
            ),
          );
          continue;
        }
        final name = resolveAlias(normalizeName(rawName), aliases);
        final key = 'item:$name|${_unitGroup(ing.unit)}';
        names[key] = name;
        (amounts[key] ??= []).add(Amount(q * factor, ing.unit));
      }
    }

    return [
      for (final e in amounts.entries)
        ShoppingEntry(
          key: e.key,
          name: names[e.key]!,
          label: names[e.key]!,
          amount: sumAmounts(e.value),
        ),
      ...unquantified.values,
    ];
  }

  String _unitGroup(String? unit) {
    if (unit == null) return 'count';
    final def = Units.bySymbol(unit);
    if (def == null) return 'unit:$unit';
    return def.isConvertible ? def.dimension.name : 'unit:${def.symbol}';
  }
}

class ManualItem {
  const ManualItem({required this.id, required this.text, this.checked = false});

  final int id;
  final String text;
  final bool checked;
}

class ShoppingRow {
  const ShoppingRow({
    required this.key,
    required this.label,
    required this.name,
    required this.section,
    required this.checked,
    this.amount,
    this.manualId,
  });

  final String key;
  final String label;

  /// Normalized name, used for aliases and section overrides.
  final String name;
  final Amount? amount;
  final StoreSection section;
  final bool checked;
  final int? manualId;

  bool get isManual => manualId != null;
}

/// Combines computed entries with persisted state into the displayed list.
class ShoppingListBuilder {
  ShoppingListBuilder(this.sections);

  final SectionResolver sections;

  /// [checks] maps entry key to the quantity (in base units) the item had
  /// when it was checked, or null when it has no quantity.
  List<ShoppingRow> build({
    required List<ShoppingEntry> entries,
    required List<ManualItem> manualItems,
    required Map<String, double?> checks,
  }) {
    final rows = <ShoppingRow>[
      for (final e in entries)
        ShoppingRow(
          key: e.key,
          label: e.label,
          name: e.name,
          amount: e.amount,
          section: sections.resolve(e.name),
          checked: isStillChecked(e, checks),
        ),
      for (final m in manualItems)
        ShoppingRow(
          key: 'manual:${m.id}',
          label: m.text,
          name: normalizeName(m.text),
          section: sections.resolve(normalizeName(m.text)),
          checked: m.checked,
          manualId: m.id,
        ),
    ];
    rows.sort((a, b) {
      final s = a.section.index.compareTo(b.section.index);
      if (s != 0) return s;
      if (a.checked != b.checked) return a.checked ? 1 : -1;
      return normalizeName(a.label).compareTo(normalizeName(b.label));
    });
    return rows;
  }

  /// SHOP-7, SHOP-8: checked only if the check exists and the quantity has
  /// not grown since.
  static bool isStillChecked(ShoppingEntry e, Map<String, double?> checks) {
    if (!checks.containsKey(e.key)) return false;
    final checkedAt = checks[e.key];
    final amount = e.amount;
    if (amount == null || checkedAt == null) return true;
    return toBaseValue(amount) <= checkedAt + 1e-6;
  }
}
