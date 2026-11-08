import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/recipe.dart';
import '../common/format.dart';
import 'recipe_book_screen.dart';
import 'recipe_editor_screen.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final int recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref.watch(recipeProvider(recipeId)).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe?.title ?? ''),
        actions: [
          if (recipe != null) ...[
            IconButton(
              tooltip: 'Modifica',
              icon: const Icon(Icons.edit),
              onPressed: () => openRecipeEditor(context, recipe),
            ),
            IconButton(
              tooltip: 'Elimina',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, recipe),
            ),
          ],
        ],
      ),
      body: recipe == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (recipe.thumbnail != null)
                  Center(child: RecipeThumbnail(recipe.thumbnail, size: 160)),
                Text(
                  '${formatNumber(recipe.servings)} porzioni',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (recipe.sourceUrl != null)
                  InkWell(
                    onLongPress: () => Clipboard.setData(
                      ClipboardData(text: recipe.sourceUrl!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        recipe.sourceUrl!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Ingredienti',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                // RCP-4: always the original line.
                for (final i in recipe.ingredients)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• ${i.original}'),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Preparazione',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final (n, step) in recipe.steps.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${n + 1}. $step'),
                  ),
              ],
            ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Recipe r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminare "${r.title}"?'),
        content: const Text(
          'I pasti già pianificati con questa ricetta resteranno come testo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(recipeRepositoryProvider).delete(r.id!);
    if (context.mounted) Navigator.pop(context);
  }
}
