import 'units.dart';

class ParsedIngredient {
  const ParsedIngredient({this.quantity, this.unit, this.name});

  final double? quantity;

  /// Canonical unit symbol from [Units], or null.
  final String? unit;
  final String? name;
}

/// Parses Italian ingredient lines (PARSE-1..6). Never throws: anything it
/// cannot understand comes back without a quantity, so the original line is
/// shown untouched in the shopping list (SHOP-4).
class IngredientParser {
  const IngredientParser();

  static const _fractions = <String, double>{
    '½': 1 / 2,
    '¼': 1 / 4,
    '¾': 3 / 4,
    '⅓': 1 / 3,
    '⅔': 2 / 3,
    '⅛': 1 / 8,
    '⅕': 1 / 5,
  };
  static const _fracChars = '½¼¾⅓⅔⅛⅕';

  // A single quantity; integers may not have a leading zero ("00" is part
  // of a flour name, not a number).
  static const _num = r'(?:0|[1-9]\d*)(?:[.,]\d+)?(?!\d)';
  // 1½ | 1 1/2 | 1/2 | ½ | 1,5
  static const _single =
      '(?:\\d+\\s*[$_fracChars]|\\d+\\s+\\d+/\\d+|'
      '\\d+/\\d+|[$_fracChars]|$_num)';
  static final _qty = '$_single(?:\\s*[-–]\\s*$_single)?';

  static final _leadingQty = RegExp('^($_qty)');
  static final _leadingWordOne = RegExp(
    r"^(?:uno|una|un)(?:\s+|')",
    caseSensitive: false,
  );
  static final _unitToken = RegExp(r'^\s*([a-zA-Z]+\.?)(?![a-zA-Z])');
  static final _leadingUnitThenQty = RegExp(
    '^([a-zA-Z]+\\.?)\\s+($_qty)(?=\\s|\$)',
  );
  static final _trailing = RegExp(
    '^(.*\\S)\\s+($_qty)\\s*([a-zA-Z]+\\.?)?\\s*\$',
  );
  static final _vague = RegExp(
    r"q\.?\s?b\.?(?![a-z])|quanto basta|a piacere|"
    r"(?:un pizzico|un filo|una manciata|una noce|una presa|qualche)"
    r"(?:\s+di\s+|\s+d'|\s+|$)",
    caseSensitive: false,
  );
  static final _parenthetical = RegExp(r'\([^)]*\)');
  static final _leadingDi = RegExp(r"^(?:di\s+|d')", caseSensitive: false);

  ParsedIngredient parse(String line) {
    var s = line
        .replaceAll('\u2019', "'")
        .replaceAll('\u00a0', ' ')
        .replaceAll(_parenthetical, ' ')
        .trim();
    if (s.isEmpty) return const ParsedIngredient();

    if (_vague.hasMatch(s)) {
      return ParsedIngredient(name: _cleanName(s.replaceAll(_vague, ' ')));
    }

    // "200 g di farina", "2-3 uova", "1/2 cipolla"
    final lead = _leadingQty.firstMatch(s);
    if (lead != null) {
      return _withUnit(_parseQty(lead.group(1)!), s.substring(lead.end));
    }

    // "una cipolla", "un'arancia"
    final one = _leadingWordOne.firstMatch(s);
    if (one != null) {
      return _withUnit(1, s.substring(one.end));
    }

    // "g 200 farina"
    final unitFirst = _leadingUnitThenQty.firstMatch(s);
    if (unitFirst != null) {
      final unit = Units.lookup(unitFirst.group(1)!);
      if (unit != null) {
        return ParsedIngredient(
          quantity: _parseQty(unitFirst.group(2)!),
          unit: unit.symbol,
          name: _cleanName(s.substring(unitFirst.end)),
        );
      }
    }

    // "Spaghetti 320 g", "Uova 2"
    final trail = _trailing.firstMatch(s);
    if (trail != null) {
      final unitRaw = trail.group(3);
      final unit = unitRaw == null ? null : Units.lookup(unitRaw);
      if (unitRaw == null || unit != null) {
        return ParsedIngredient(
          quantity: _parseQty(trail.group(2)!),
          unit: unit?.symbol,
          name: _cleanName(trail.group(1)!),
        );
      }
    }

    return ParsedIngredient(name: _cleanName(s));
  }

  ParsedIngredient _withUnit(double quantity, String rest) {
    final m = _unitToken.firstMatch(rest);
    if (m != null) {
      final unit = Units.lookup(m.group(1)!);
      if (unit != null) {
        return ParsedIngredient(
          quantity: quantity,
          unit: unit.symbol,
          name: _cleanName(rest.substring(m.end)),
        );
      }
    }
    return ParsedIngredient(quantity: quantity, name: _cleanName(rest));
  }

  double _parseQty(String raw) {
    final parts = raw.split(RegExp('\\s*[-–]\\s*(?=[\\d$_fracChars])'));
    return parts.map(_parseSingle).reduce((a, b) => a > b ? a : b);
  }

  double _parseSingle(String raw) {
    final s = raw.trim();
    final fracChar = s.isEmpty ? null : _fractions[s[s.length - 1]];
    if (fracChar != null) {
      final whole = s.substring(0, s.length - 1).trim();
      return (whole.isEmpty ? 0 : int.parse(whole)) + fracChar;
    }
    final mixed = RegExp(r'^(\d+)\s+(\d+)/(\d+)$').firstMatch(s);
    if (mixed != null) {
      return int.parse(mixed.group(1)!) +
          int.parse(mixed.group(2)!) / int.parse(mixed.group(3)!);
    }
    final frac = RegExp(r'^(\d+)/(\d+)$').firstMatch(s);
    if (frac != null) {
      return int.parse(frac.group(1)!) / int.parse(frac.group(2)!);
    }
    return double.parse(s.replaceAll(',', '.'));
  }

  String? _cleanName(String raw) {
    var s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceFirst(_leadingDi, '').trim();
    s = s.replaceAll(RegExp(r'^[,;:.\-\s]+|[,;:.\-\s]+$'), '');
    return s.isEmpty ? null : s;
  }
}
