import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/calendar.dart';
import '../../domain/shopping.dart';
import '../../domain/store_section.dart';
import '../../domain/units.dart';
import '../common/format.dart';

/// The week's shopping list, always in sync with the plan (SHOP-1, SHOP-7).
class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  Week? _week;
  final _manual = TextEditingController();

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Week current = ref.watch(currentWeekProvider);
    final week = _week ?? current;
    final rows = ref.watch(shoppingListProvider(week));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spesa'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Settimana precedente',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _week = week.previous),
              ),
              Text(weekRange(week)),
              IconButton(
                tooltip: 'Settimana successiva',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _week = week.next),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              key: const Key('manual-item-field'),
              controller: _manual,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.add),
                hintText: 'Aggiungi alla lista',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                ref.read(shoppingRepositoryProvider).addManualItem(week, v);
                _manual.clear();
              },
            ),
          ),
          Expanded(
            child: switch (rows) {
              AsyncData(:final value) when value.isEmpty => const Center(
                child: Text('La lista è vuota'),
              ),
              AsyncData(:final value) => _ShoppingList(week: week, rows: value),
              AsyncError(:final error) => Center(child: Text('$error')),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _ShoppingList extends ConsumerWidget {
  const _ShoppingList({required this.week, required this.rows});

  final Week week;
  final List<ShoppingRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = <Widget>[];
    StoreSection? current;
    for (final row in rows) {
      if (row.section != current) {
        current = row.section;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              sectionLabels[current]!,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        );
      }
      children.add(_RowTile(week: week, row: row, all: rows));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }
}

class _RowTile extends ConsumerWidget {
  const _RowTile({required this.week, required this.row, required this.all});

  final Week week;
  final ShoppingRow row;
  final List<ShoppingRow> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(shoppingRepositoryProvider);
    final amount = row.amount;
    return CheckboxListTile(
      key: Key('row-${row.key}'),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      value: row.checked,
      title: Text(
        row.label,
        style: row.checked
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      secondary: GestureDetector(
        onTap: () => _menu(context, ref),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (amount != null) Text(formatAmount(amount)),
            const Icon(Icons.more_vert, size: 20),
          ],
        ),
      ),
      onChanged: (checked) {
        if (row.manualId != null) {
          repo.setManualChecked(row.manualId!, checked ?? false);
        } else if (checked ?? false) {
          repo.check(
            week,
            row.key,
            amount == null ? null : toBaseValue(amount),
          );
        } else {
          repo.uncheck(week, row.key);
        }
      },
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(shoppingRepositoryProvider);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Cambia reparto'),
              onTap: () => Navigator.pop(context, 'section'),
            ),
            if (!row.isManual)
              ListTile(
                leading: const Icon(Icons.merge),
                title: const Text('Unisci con…'),
                onTap: () => Navigator.pop(context, 'merge'),
              ),
            if (row.isManual)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Elimina'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'section': // SHOP-15
        final section = await showDialog<StoreSection>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Reparto'),
            children: [
              for (final s in StoreSection.values)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, s),
                  child: Text(sectionLabels[s]!),
                ),
            ],
          ),
        );
        if (section != null) await repo.setSectionOverride(row.name, section);
      case 'merge': // SHOP-12
        final targets =
            all
                .where((r) => !r.isManual && r.name != row.name)
                .map((r) => r.name)
                .toSet()
                .toList()
              ..sort();
        final target = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text('Unisci "${row.name}" con'),
            children: [
              for (final t in targets)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, t),
                  child: Text(t),
                ),
            ],
          ),
        );
        if (target != null) await repo.addAlias(row.name, target);
      case 'delete':
        await repo.removeManualItem(row.manualId!);
    }
  }
}
