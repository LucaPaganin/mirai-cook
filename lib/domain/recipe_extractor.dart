import 'dart:convert';

import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart' as html_parser;

/// Recipe data found in a web page, before review (IMP-3).
class ExtractedRecipe {
  const ExtractedRecipe({
    required this.title,
    this.servings,
    this.ingredients = const [],
    this.steps = const [],
    this.imageUrl,
  });

  final String title;
  final double? servings;
  final List<String> ingredients;
  final List<String> steps;
  final String? imageUrl;
}

/// Extracts schema.org `Recipe` JSON-LD from HTML. Pure Dart.
class RecipeExtractor {
  const RecipeExtractor();

  ExtractedRecipe? extract(String html) {
    final doc = html_parser.parse(html);
    for (final script in doc.querySelectorAll(
      'script[type="application/ld+json"]',
    )) {
      final Object? json;
      try {
        json = jsonDecode(script.text);
      } on FormatException {
        continue;
      }
      final recipe = _findRecipe(json);
      if (recipe != null) {
        final title = _clean(recipe['name']);
        if (title.isEmpty) continue;
        return ExtractedRecipe(
          title: title,
          servings: parseYield(recipe['recipeYield']),
          ingredients: _strings(recipe['recipeIngredient'])
              .map(_clean)
              .where((s) => s.isNotEmpty)
              .toList(),
          steps: _steps(recipe['recipeInstructions']),
          imageUrl: _image(recipe['image']),
        );
      }
    }
    return null;
  }

  /// `og:title` or `<title>`, used when no Recipe is found (IMP-5).
  String? pageTitle(String html) {
    final doc = html_parser.parse(html);
    final og = doc
        .querySelector('meta[property="og:title"]')
        ?.attributes['content'];
    final title = _clean(og ?? doc.querySelector('title')?.text);
    return title.isEmpty ? null : title;
  }

  static double? parseYield(Object? value) {
    if (value is num) return value.toDouble();
    if (value is List) {
      for (final v in value) {
        final n = parseYield(v);
        if (n != null) return n;
      }
      return null;
    }
    if (value is String) {
      final numbers = RegExp(r'\d+(?:[.,]\d+)?')
          .allMatches(value)
          .map((m) => double.parse(m.group(0)!.replaceAll(',', '.')))
          .toList();
      if (numbers.isEmpty) return null;
      // "2-3" -> 3, like ingredient ranges (PARSE-4).
      return numbers.take(2).reduce((a, b) => a > b ? a : b);
    }
    return null;
  }

  Map<String, Object?>? _findRecipe(Object? node) {
    if (node is List) {
      for (final n in node) {
        final r = _findRecipe(n);
        if (r != null) return r;
      }
    } else if (node is Map<String, Object?>) {
      if (_isRecipe(node['@type'])) return node;
      final graph = node['@graph'];
      if (graph != null) return _findRecipe(graph);
      final main = node['mainEntity'];
      if (main != null) return _findRecipe(main);
    }
    return null;
  }

  bool _isRecipe(Object? type) => type is String
      ? type == 'Recipe'
      : type is List && type.contains('Recipe');

  List<String> _steps(Object? value) {
    final out = <String>[];
    void visit(Object? v) {
      if (v is String) {
        out.addAll(
          _clean(
            v,
            keepNewlines: true,
          ).split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty),
        );
      } else if (v is List) {
        v.forEach(visit);
      } else if (v is Map) {
        if (v['itemListElement'] != null) {
          visit(v['itemListElement']);
        } else {
          final text = _clean(v['text'] ?? v['name']);
          if (text.isNotEmpty) out.add(text);
        }
      }
    }

    visit(value);
    return out;
  }

  String? _image(Object? value) {
    if (value is String) return value.isEmpty ? null : value;
    if (value is List) {
      for (final v in value) {
        final url = _image(v);
        if (url != null) return url;
      }
    }
    if (value is Map) return _image(value['url'] ?? value['contentUrl']);
    return null;
  }

  List<String> _strings(Object? value) => switch (value) {
    String s => [s],
    List l => l.whereType<String>().toList(),
    _ => const [],
  };

  /// Decodes HTML entities and strips tags.
  String _clean(Object? value, {bool keepNewlines = false}) {
    if (value is! String) return '';
    var s = value;
    if (s.contains('<') || s.contains('&')) {
      final Document doc = html_parser.parse('<body>$s</body>');
      s = doc.body?.text ?? s;
      // Entity-encoded markup (e.g. "&lt;p&gt;") needs a second pass.
      if (s.contains('<')) s = html_parser.parse('<body>$s</body>').body!.text;
    }
    s = s.replaceAll(' ', ' ');
    return keepNewlines
        ? s.replaceAll(RegExp(r'[ \t]+'), ' ').trim()
        : s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
