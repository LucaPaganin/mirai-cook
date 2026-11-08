import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/calendar.dart';
import '../../domain/meal.dart';
import '../../domain/recipe_matching.dart';
import '../../domain/suggestion_ranker.dart';
import '../common/format.dart';
import 'week_screen.dart';

/// PLAN-5: bottom sheet with the slot's items and a focused text field.
Future<void> showSlotSheet(BuildContext context, SlotId slot) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SlotSheet(slot: slot),
    );

class SlotSheet extends ConsumerStatefulWidget {
  const SlotSheet({super.key, required this.slot});

  final SlotId slot;

  @override
  ConsumerState<SlotSheet> createState() => _SlotSheetState();
}

class _SlotSheetState extends ConsumerState<SlotSheet> {
  final _text = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _add(SlotItem item) async {
    await ref.read(planRepositoryProvider).addItem(widget.slot, item);
    if (mounted) Navigator.pop(context); // PLAN-7
  }

  Future<void> _addSuggestion(Suggestion s) async {
    if (s.isRecipe) {
      final servings = await ref.read(defaultServingsProvider.future);
      await _add(RecipeItem(recipeId: s.recipeId!, servings: servings));
    } else {
      await _add(FreeTextItem(s.label));
    }
  }

  Future<void> _submit() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    // PLAN-19: text equal to a recipe title becomes a recipe reference.
    final recipes = await ref.read(recipeIndexProvider.future);
    final recipeId = matchRecipeByTitle(text, recipes.values);
    if (recipeId == null) {
      await _add(FreeTextItem(text));
    } else {
      final servings = await ref.read(defaultServingsProvider.future);
      await _add(RecipeItem(recipeId: recipeId, servings: servings));
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final week = Week.containing(slot.date);
    final items =
        ref.watch(weekPlanProvider(week)).value?[slot] ?? const <SlotItem>[];
    final recipes = ref.watch(recipeIndexProvider).value ?? const {};
    final defaultServings = ref.watch(defaultServingsProvider).value ?? 1;
    final suggestions =
        ref.watch(slotSuggestionsProvider(_query)).value ?? const [];
    final repo = ref.read(planRepositoryProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${mealLabels[slot.meal]} · ${weekdayName(slot.date)} '
                '${shortDate(slot.date)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final (index, item) in items.indexed)
              // PLAN-16: swipe or tap the bin to remove an item.
              Dismissible(
                key: ValueKey('item-$index-${item.hashCode}'),
                // Delete before the widget leaves, so the list from the
                // database no longer contains it when the sheet rebuilds.
                confirmDismiss: (_) async {
                  await repo.removeItemAt(slot, index);
                  return true;
                },
                background: Container(color: Colors.red.shade100),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    item is RecipeItem ? Icons.menu_book : Icons.notes,
                  ),
                  title: Text(slotItemLabel(item, recipes, defaultServings)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item is RecipeItem)
                        _ServingsStepper(
                          servings: item.servings,
                          onChanged: (v) =>
                              repo.setServingsAt(slot, index, v), // PLAN-12
                        ),
                      IconButton(
                        key: Key('remove-item-$index'),
                        tooltip: 'Rimuovi',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => repo.removeItemAt(slot, index),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                key: const Key('slot-field'),
                controller: _text,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: items.isEmpty ? 'Cosa si mangia?' : 'Aggiungi…',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (_) => _submit(),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final s in suggestions.take(8))
                    ListTile(
                      key: Key('suggestion-${s.label}'),
                      leading: Icon(
                        s.isRecipe ? Icons.menu_book : Icons.history,
                      ),
                      title: Text(s.label),
                      onTap: () => _addSuggestion(s),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServingsStepper extends StatelessWidget {
  const _ServingsStepper({required this.servings, required this.onChanged});

  final double servings;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Meno porzioni',
        icon: const Icon(Icons.remove),
        onPressed: servings > 1 ? () => onChanged(servings - 1) : null,
      ),
      Text(formatNumber(servings)),
      IconButton(
        tooltip: 'Più porzioni',
        icon: const Icon(Icons.add),
        onPressed: () => onChanged(servings + 1),
      ),
    ],
  );
}
