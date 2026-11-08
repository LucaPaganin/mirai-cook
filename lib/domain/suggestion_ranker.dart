import 'dart:math' as math;

import 'calendar.dart';
import 'name_normalizer.dart';

/// A candidate for the slot field: a recipe or a previously used free text,
/// with the dates on which it was planned.
class Suggestion {
  const Suggestion.recipe(int this.recipeId, this.label, this.uses);
  const Suggestion.freeText(this.label, this.uses) : recipeId = null;

  final int? recipeId;
  final String label;
  final List<CalendarDate> uses;

  bool get isRecipe => recipeId != null;
}

/// Ranks suggestions by frequency and recency (PLAN-6): each use weighs
/// 0.5^(age in days / halfLifeDays), so a recent use counts more than an old
/// one and many uses count more than few.
class SuggestionRanker {
  const SuggestionRanker({this.halfLifeDays = 30, this.limit = 20});

  final double halfLifeDays;
  final int limit;

  double score(List<CalendarDate> uses, CalendarDate today) {
    var total = 0.0;
    for (final d in uses) {
      final age = d.daysUntil(today).clamp(0, 1 << 30);
      total += math.pow(2, -age / halfLifeDays);
    }
    return total;
  }

  List<Suggestion> rank(
    String query,
    List<Suggestion> candidates,
    CalendarDate today,
  ) {
    final merged = _foldFreeTextsIntoRecipes(candidates);
    final tokens = normalizeName(query).split(' ').where((t) => t.isNotEmpty);
    final matches = merged.where((c) => _matches(c.label, tokens)).toList();
    final scores = {for (final c in matches) c: score(c.uses, today)};
    matches.sort((a, b) {
      final s = scores[b]!.compareTo(scores[a]!);
      if (s != 0) return s;
      if (a.isRecipe != b.isRecipe) return a.isRecipe ? -1 : 1;
      return normalizeName(a.label).compareTo(normalizeName(b.label));
    });
    return matches.take(limit).toList();
  }

  bool _matches(String label, Iterable<String> tokens) {
    final words = normalizeName(label).split(RegExp(r"[\s']+"));
    return tokens.every((t) => words.any((w) => w.startsWith(t)));
  }

  List<Suggestion> _foldFreeTextsIntoRecipes(List<Suggestion> candidates) {
    final recipes = <String, Suggestion>{};
    for (final c in candidates.where((c) => c.isRecipe)) {
      recipes[normalizeName(c.label)] = c;
    }
    final result = <Suggestion>[];
    final extraUses = <String, List<CalendarDate>>{};
    for (final c in candidates.where((c) => !c.isRecipe)) {
      final key = normalizeName(c.label);
      if (recipes.containsKey(key)) {
        (extraUses[key] ??= []).addAll(c.uses);
      } else {
        result.add(c);
      }
    }
    for (final e in recipes.entries) {
      final extra = extraUses[e.key];
      final r = e.value;
      result.add(extra == null
          ? r
          : Suggestion.recipe(r.recipeId!, r.label, [...r.uses, ...extra]));
    }
    return result;
  }
}
