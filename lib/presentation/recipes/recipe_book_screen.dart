import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/recipe.dart';
import '../../domain/tags.dart';
import '../import/import_screen.dart';
import 'recipe_detail_screen.dart';
import 'recipe_editor_screen.dart';

/// RCP-1, RCP-9: all recipes, searchable by title and filterable by tags.
class RecipeBookScreen extends ConsumerStatefulWidget {
  const RecipeBookScreen({super.key});

  @override
  ConsumerState<RecipeBookScreen> createState() => _RecipeBookScreenState();
}

class _RecipeBookScreenState extends ConsumerState<RecipeBookScreen> {
  String _query = '';

  /// Selected tag keys.
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final allTags = ref.watch(recipeTagsProvider).value ?? const <String>[];
    // Drop selections whose tag no longer exists.
    _selected.retainAll(allTags.map(tagKey));
    final tagKeys = (_selected.toList()..sort()).join('|');
    final recipes = ref.watch(filteredRecipesProvider(_query, tagKeys));
    final filtering = _query.isNotEmpty || _selected.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ricette'),
        actions: [
          IconButton(
            tooltip: 'Importa da URL',
            icon: const Icon(Icons.link),
            onPressed: () => showImportDialog(context), // IMP-2
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
          if (allTags.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final tag in allTags)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        key: Key('tag-filter-$tag'),
                        label: Text(tag),
                        selected: _selected.contains(tagKey(tag)),
                        onSelected: (on) => setState(() {
                          on
                              ? _selected.add(tagKey(tag))
                              : _selected.remove(tagKey(tag));
                        }),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: switch (recipes) {
              AsyncData(:final value) when value.isEmpty => Center(
                child: Text(
                  filtering
                      ? 'Nessun risultato'
                      : 'Nessuna ricetta. Aggiungine una con +',
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
