enum Dimension { mass, volume, other }

class UnitDef {
  const UnitDef(this.symbol, this.dimension, [this.toBase = 1]);

  /// Canonical symbol stored in the database.
  final String symbol;
  final Dimension dimension;

  /// Factor to the dimension's base unit (g for mass, ml for volume).
  final double toBase;

  bool get isConvertible => dimension != Dimension.other;
}

/// Fixed unit table for Italian recipes (SHOP-10, PARSE-5).
class Units {
  Units._();

  static const _defs = <UnitDef>[
    UnitDef('g', Dimension.mass),
    UnitDef('hg', Dimension.mass, 100),
    UnitDef('kg', Dimension.mass, 1000),
    UnitDef('ml', Dimension.volume),
    UnitDef('cl', Dimension.volume, 10),
    UnitDef('dl', Dimension.volume, 100),
    UnitDef('l', Dimension.volume, 1000),
    UnitDef('cucchiaio', Dimension.volume, 15),
    UnitDef('cucchiaino', Dimension.volume, 5),
    UnitDef('spicchio', Dimension.other),
    UnitDef('foglia', Dimension.other),
    UnitDef('rametto', Dimension.other),
    UnitDef('ciuffo', Dimension.other),
    UnitDef('mazzetto', Dimension.other),
    UnitDef('bustina', Dimension.other),
    UnitDef('cubetto', Dimension.other),
    UnitDef('fetta', Dimension.other),
    UnitDef('pezzo', Dimension.other),
    UnitDef('vasetto', Dimension.other),
    UnitDef('barattolo', Dimension.other),
    UnitDef('scatola', Dimension.other),
    UnitDef('confezione', Dimension.other),
    UnitDef('lattina', Dimension.other),
    UnitDef('bicchiere', Dimension.other),
    UnitDef('tazza', Dimension.other),
    UnitDef('tazzina', Dimension.other),
    UnitDef('gambo', Dimension.other),
    UnitDef('costa', Dimension.other),
    UnitDef('filetto', Dimension.other),
  ];

  /// Spelling variants (lowercase, accent-free, no trailing dot).
  static const _aliases = <String, String>{
    'g': 'g',
    'gr': 'g',
    'grammo': 'g',
    'grammi': 'g',
    'hg': 'hg',
    'etto': 'hg',
    'etti': 'hg',
    'kg': 'kg',
    'chilo': 'kg',
    'chili': 'kg',
    'chilogrammo': 'kg',
    'chilogrammi': 'kg',
    'ml': 'ml',
    'millilitro': 'ml',
    'millilitri': 'ml',
    'cl': 'cl',
    'centilitro': 'cl',
    'centilitri': 'cl',
    'dl': 'dl',
    'decilitro': 'dl',
    'decilitri': 'dl',
    'l': 'l',
    'lt': 'l',
    'litro': 'l',
    'litri': 'l',
    'cucchiaio': 'cucchiaio',
    'cucchiai': 'cucchiaio',
    'cucch': 'cucchiaio',
    'cucchiaino': 'cucchiaino',
    'cucchiaini': 'cucchiaino',
    'spicchio': 'spicchio',
    'spicchi': 'spicchio',
    'foglia': 'foglia',
    'foglie': 'foglia',
    'foglioline': 'foglia',
    'fogliolina': 'foglia',
    'rametto': 'rametto',
    'rametti': 'rametto',
    'rami': 'rametto',
    'ramo': 'rametto',
    'ciuffo': 'ciuffo',
    'ciuffi': 'ciuffo',
    'mazzetto': 'mazzetto',
    'mazzetti': 'mazzetto',
    'mazzo': 'mazzetto',
    'bustina': 'bustina',
    'bustine': 'bustina',
    'cubetto': 'cubetto',
    'cubetti': 'cubetto',
    'dado': 'cubetto',
    'dadi': 'cubetto',
    'fetta': 'fetta',
    'fette': 'fetta',
    'fettina': 'fetta',
    'fettine': 'fetta',
    'pezzo': 'pezzo',
    'pezzi': 'pezzo',
    'vasetto': 'vasetto',
    'vasetti': 'vasetto',
    'barattolo': 'barattolo',
    'barattoli': 'barattolo',
    'scatola': 'scatola',
    'scatole': 'scatola',
    'confezione': 'confezione',
    'confezioni': 'confezione',
    'lattina': 'lattina',
    'lattine': 'lattina',
    'bicchiere': 'bicchiere',
    'bicchieri': 'bicchiere',
    'tazza': 'tazza',
    'tazze': 'tazza',
    'tazzina': 'tazzina',
    'tazzine': 'tazzina',
    'gambo': 'gambo',
    'gambi': 'gambo',
    'costa': 'costa',
    'coste': 'costa',
    'filetto': 'filetto',
    'filetti': 'filetto',
  };

  static final Map<String, UnitDef> _bySymbol = {
    for (final d in _defs) d.symbol: d,
  };

  /// Resolves a raw token (e.g. "Grammi", "kg.") to a unit, or null.
  static UnitDef? lookup(String token) {
    final key = token.toLowerCase().replaceAll('.', '');
    final symbol = _aliases[key];
    return symbol == null ? null : _bySymbol[symbol];
  }

  static UnitDef? bySymbol(String? symbol) =>
      symbol == null ? null : _bySymbol[symbol];
}

/// A quantity expressed in some unit (null unit = plain count).
class Amount {
  const Amount(this.value, this.unit);

  final double value;
  final String? unit;

  @override
  bool operator ==(Object other) =>
      other is Amount &&
      (other.value - value).abs() < 1e-9 &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(value.toStringAsFixed(6), unit);

  @override
  String toString() => 'Amount($value $unit)';
}

/// Sums amounts sharing a dimension (or the same non-convertible unit) and
/// expresses the result in the most readable unit (SHOP-10).
Amount sumAmounts(List<Amount> amounts) {
  assert(amounts.isNotEmpty);
  final units = amounts.map((a) => a.unit).toSet();
  if (units.length == 1) {
    return Amount(amounts.fold(0.0, (s, a) => s + a.value), units.single);
  }
  final defs = amounts.map((a) => Units.bySymbol(a.unit)!).toList();
  final dimension = defs.first.dimension;
  assert(defs.every((d) => d.dimension == dimension && d.isConvertible));
  var base = 0.0;
  for (var i = 0; i < amounts.length; i++) {
    base += amounts[i].value * defs[i].toBase;
  }
  return readable(base, dimension);
}

/// Expresses a base-unit quantity as g/kg or ml/l.
Amount readable(double base, Dimension dimension) {
  switch (dimension) {
    case Dimension.mass:
      return base >= 1000 ? Amount(base / 1000, 'kg') : Amount(base, 'g');
    case Dimension.volume:
      return base >= 1000 ? Amount(base / 1000, 'l') : Amount(base, 'ml');
    case Dimension.other:
      throw ArgumentError('Dimension.other has no base unit');
  }
}

/// Value of [amount] in its dimension's base unit, for comparisons.
double toBaseValue(Amount amount) {
  final def = Units.bySymbol(amount.unit);
  if (def == null || !def.isConvertible) return amount.value;
  return amount.value * def.toBase;
}
