import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/backup_service.dart';
import '../../application/providers.dart';
import '../../data/backup/backup_target.dart';

String formatDateTime(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.day}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}

/// DATA-15: snapshots with date/time and recipe count.
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  late Future<List<SnapshotInfo>> _snapshots = ref
      .read(backupControllerProvider)
      .listSnapshots();
  bool _busy = false;

  Future<void> _restore(SnapshotInfo s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ripristinare questo backup?'),
        content: const Text(
          'I dati attuali verranno sostituiti. Prima del ripristino viene '
          'salvata una copia locale, così potrai annullarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ripristina'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final outcome = await ref.read(backupControllerProvider).restore(s);
    if (!mounted) return;
    setState(() => _busy = false);
    await showRestoreOutcome(context, outcome);
    if (outcome is RestoreDone && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ripristina da Drive')),
    body: _busy
        ? const Center(child: CircularProgressIndicator())
        : FutureBuilder<List<SnapshotInfo>>(
            future: _snapshots,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Impossibile leggere i backup: ${snap.error}'),
                      TextButton(
                        onPressed: () => setState(
                          () => _snapshots = ref
                              .read(backupControllerProvider)
                              .listSnapshots(),
                        ),
                        child: const Text('Riprova'),
                      ),
                    ],
                  ),
                );
              }
              final list = snap.data;
              if (list == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (list.isEmpty) {
                return const Center(
                  child: Text('Nessun backup trovato su Drive'),
                );
              }
              return ListView(
                children: [
                  for (final s in list)
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(formatDateTime(s.createdAt)),
                      subtitle: Text(
                        s.recipeCount == null
                            ? s.name
                            : '${s.recipeCount} ricette',
                      ),
                      onTap: () => _restore(s),
                    ),
                ],
              );
            },
          ),
  );
}

/// DATA-10 and friends: explains why a restore was refused.
Future<void> showRestoreOutcome(
  BuildContext context,
  RestoreOutcome outcome,
) async {
  final (title, body) = switch (outcome) {
    RestoreDone() => (
      'Ripristino completato',
      'I dati sono stati ripristinati.',
    ),
    RestoreRefused(
      validation: SnapshotTooNew(:final schemaVersion, :final supported),
    ) =>
      (
        'Backup non compatibile',
        'Questo backup è stato creato da una versione più recente di '
            'Mirai Cook (schema $schemaVersion, questa app supporta fino a '
            '$supported). Aggiorna l\'app e riprova.',
      ),
    RestoreRefused(validation: SnapshotInvalid(:final reason)) => (
      'Backup non valido',
      '$reason. I dati attuali non sono stati modificati.',
    ),
    RestoreRefused() => (
      'Backup non valido',
      'I dati attuali non sono stati modificati.',
    ),
    RestoreFailed(:final message) => (
      'Ripristino non riuscito',
      '$message\nI dati attuali non sono stati modificati.',
    ),
  };
  if (outcome is RestoreDone) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body)));
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
