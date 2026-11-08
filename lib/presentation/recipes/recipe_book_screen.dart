import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/recipe.dart';
import 'recipe_detail_screen.dart';
import 'recipe_editor_screen.dart';

/// RCP-1: all recipes, searchable by title.
class RecipeBookScreen extends ConsumerStatefulWidget {
  const RecipeBookScreen({super.key, this.onImport});

  /// Opens the import-from-URL flow (IMP-2).
  final VoidCallback? onImport;

  @override
  ConsumerState<RecipeBookScreen> createState() => _RecipeBookScreenState();
}

class _RecipeBookScreenState extends ConsumerState<RecipeBookScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(recipeListProvider(_query));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ricette'),
        actions: [
          if (widget.onImport != null)
            IconButton(
              tooltip: 'Importa da URL',
              icon: const Icon(Icons.link),
              onPressed: widget.onImport,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nuova ricetta',
        onPressed: () =>
            openRecipeEditor(context, const Recipe(title: '', servings: 4)),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              key: const Key('recipe-search'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cerca per titolo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: switch (recipes) {
              AsyncData(:final value) when value.isEmpty => Center(
                child: Text(
                  _query.isEmpty
                      ? 'Nessuna ricetta. Aggiungine una con +'
                      : 'Nessun risultato',
                ),
              ),
              AsyncData(:final value) => ListView.builder(
                itemCount: value.length,
                itemBuilder: (context, i) => _RecipeTile(value[i]),
              ),
              AsyncError(:final error) => Center(child: Text('$error')),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile(this.recipe);

  final RecipeSummary recipe;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: RecipeThumbnail(recipe.thumbnail),
    title: Text(recipe.title),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
      ),
    ),
  );
}

class RecipeThumbnail extends StatelessWidget {
  const RecipeThumbnail(this.bytes, {super.key, this.size = 48});

  final List<int>? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final b = bytes;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: size,
        child: b == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.restaurant),
              )
            : Image.memory(Uint8List.fromList(b), fit: BoxFit.cover),
      ),
    );
  }
}
