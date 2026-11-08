import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/ingredient_parser.dart';
import '../../domain/recipe.dart';
import '../common/format.dart';

/// Opens the editor; returns the saved recipe id, or null if cancelled.
Future<int?> openRecipeEditor(
  BuildContext context,
  Recipe initial, {
  bool replace = false,
}) {
  final route = MaterialPageRoute<int>(
    builder: (_) => RecipeEditorScreen(initial: initial),
  );
  return replace
      ? Navigator.pushReplacement<int, void>(context, route)
      : Navigator.push(context, route);
}

/// Create/edit a recipe (RCP-5). Also used to review imports: nothing is
/// persisted until "Salva" (IMP-8).
class RecipeEditorScreen extends ConsumerStatefulWidget {
  const RecipeEditorScreen({super.key, required this.initial});

  final Recipe initial;

  @override
  ConsumerState<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends ConsumerState<RecipeEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial.title);
  late final _servings = TextEditingController(
    text: formatNumber(widget.initial.servings),
  );
  late final _ingredients = TextEditingController(
    text: widget.initial.ingredients.map((i) => i.original).join('\n'),
  );
  late final _steps = TextEditingController(
    text: widget.initial.steps.join('\n'),
  );
  late final _url = TextEditingController(text: widget.initial.sourceUrl);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _servings, _ingredients, _steps, _url]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _lines(String text) =>
      text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    const parser = IngredientParser();
    final url = _url.text.trim();
    final recipe = Recipe(
      id: widget.initial.id,
      title: _title.text.trim(),
      servings: double.parse(_servings.text.replaceAll(',', '.')),
      thumbnail: widget.initial.thumbnail,
      sourceUrl: url.isEmpty ? null : url,
      steps: _lines(_steps.text),
      ingredients: [
        for (final line in _lines(_ingredients.text))
          () {
            final p = parser.parse(line);
            return IngredientLine(
              original: line,
              quantity: p.quantity,
              unit: p.unit,
              name: p.name,
            );
          }(),
      ],
    );
    final id = await ref.read(recipeRepositoryProvider).save(recipe);
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial.id == null ? 'Nuova ricetta' : 'Modifica'),
        actions: [
          TextButton(
            key: const Key('save-recipe'),
            onPressed: _saving ? null : _save,
            child: const Text('Salva'),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('recipe-title'),
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Titolo'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Inserisci un titolo' : null,
            ),
            TextFormField(
              key: const Key('recipe-servings'),
              controller: _servings,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Porzioni'),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                return n == null || n <= 0 ? 'Numero non valido' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('recipe-ingredients'),
              controller: _ingredients,
              minLines: 4,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: 'Ingredienti (uno per riga)',
                alignLabelWithHint: true,
                hintText: '200 g di farina\n2 uova\nSale q.b.',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _steps,
              minLines: 4,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Preparazione (un passaggio per riga)',
                alignLabelWithHint: true,
              ),
            ),
            TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'URL sorgente'),
            ),
          ],
        ),
      ),
    );
  }
}
