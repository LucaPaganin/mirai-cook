import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/calendar.dart';
import '../../domain/meal.dart';
import '../common/format.dart';

enum _SlotAction { move, copy, clear }

/// Long-press menu: move, copy or clear a slot (PLAN-9).
Future<void> showSlotActions(
  BuildContext context,
  WidgetRef ref,
  SlotId slot,
) async {
  final action = await showModalBottomSheet<_SlotAction>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.drive_file_move_outline),
            title: const Text('Sposta in…'),
            onTap: () => Navigator.pop(context, _SlotAction.move),
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copia in…'),
            onTap: () => Navigator.pop(context, _SlotAction.copy),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Svuota pasto'),
            onTap: () => Navigator.pop(context, _SlotAction.clear),
          ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  final repo = ref.read(planRepositoryProvider);
  if (action == _SlotAction.clear) {
    await repo.clearSlot(slot);
    return;
  }
  final target = await pickSlot(context, initial: slot);
  if (target == null) return;
  await repo.transferSlot(slot, target, move: action == _SlotAction.move);
}

Future<SlotId?> pickSlot(
  BuildContext context, {
  required SlotId initial,
}) async {
  final d = initial.date;
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime(d.year, d.month, d.day),
    firstDate: DateTime(d.year - 1),
    lastDate: DateTime(d.year + 2),
  );
  if (picked == null || !context.mounted) return null;
  final date = CalendarDate.fromDateTime(picked);
  final meal = await showDialog<MealType>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text('${weekdayName(date)} ${shortDate(date)}'),
      children: [
        for (final m in MealType.values)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, m),
            child: Text(mealLabels[m]!),
          ),
      ],
    ),
  );
  return meal == null ? null : SlotId(date, meal);
}

/// PLAN-10, PLAN-11.
Future<void> duplicatePreviousWeek(
  BuildContext context,
  WidgetRef ref,
  Week week,
) async {
  final repo = ref.read(planRepositoryProvider);
  if (await repo.hasItems(week)) {
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sovrascrivere la settimana?'),
        content: const Text(
          'Questa settimana contiene già dei pasti. Verranno sostituiti con '
          'quelli della settimana precedente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sovrascrivi'),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }
  await repo.duplicatePreviousWeek(week);
}
