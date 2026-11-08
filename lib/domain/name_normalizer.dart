/// Mechanical ingredient name normalization (SHOP-11): lowercase, trim,
/// collapse whitespace, strip accents, unify apostrophes. No plural rules.
String normalizeName(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_foldMap[ch] ?? ch);
  }
  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

const _foldMap = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
  '’': "'", '‘': "'", '`': "'", '´': "'",
  ' ': ' ',
};
