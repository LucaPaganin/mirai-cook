import 'name_normalizer.dart';

/// Identity of a tag: same rules as ingredient names (RCP-7).
String tagKey(String tag) => normalizeName(tag.replaceAll('#', ''));

/// Trims, collapses spaces, drops empty and duplicate tags (by [tagKey]),
/// keeping the first spelling and the original order.
List<String> cleanTags(Iterable<String> tags) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in tags) {
    final display = raw
        .replaceAll('#', '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    final key = tagKey(display);
    if (key.isEmpty || !seen.add(key)) continue;
    out.add(display);
  }
  return out;
}

/// Known tags whose words start with [query], excluding [chosen] (RCP-8).
List<String> suggestTags(
  String query,
  Iterable<String> known,
  Iterable<String> chosen,
) {
  final q = tagKey(query);
  if (q.isEmpty) return const [];
  final taken = chosen.map(tagKey).toSet();
  final matches = known.where((t) {
    final key = tagKey(t);
    return !taken.contains(key) && key.split(' ').any((w) => w.startsWith(q));
  }).toList()..sort((a, b) => tagKey(a).compareTo(tagKey(b)));
  return matches;
}
