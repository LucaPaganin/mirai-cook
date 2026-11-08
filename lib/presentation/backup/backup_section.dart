import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/backup_service.dart';
import '../../application/providers.dart';
import '../../data/repositories.dart';
import 'restore_screen.dart';

/// Backup settings (DATA-7, DATA-11..13, DATA-16, DATA-17).
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(settingProvider(SettingKeys.backupAccount)).value;
    final lastBackup = ref
        .watch(settingProvider(SettingKeys.lastBackupAt))
        .value;
    final lastError = ref
        .watch(settingProvider(SettingKeys.lastBackupError))
        .value;
    final keep =
        int.tryParse(
          ref.watch(settingProvider(SettingKeys.backupKeepCount)).value ?? '',
        ) ??
        BackupService.defaultKeepCount;
    final controller = ref.read(backupControllerProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final theme = Theme.of(context);

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          'Backup su Google Drive',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      if (_busy) const LinearProgressIndicator(),
    ];

    if (account == null) {
      children.addAll([
        // DATA-13
        ListTile(
          key: const Key('backup-warning'),
          leading: Icon(Icons.warning_amber, color: theme.colorScheme.error),
          title: const Text('I dati sono solo su questo telefono'),
          subtitle: const Text(
            'Collega Google Drive per salvare automaticamente una copia.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            key: const Key('connect-drive'),
            onPressed: _busy ? null : () => _run(controller.connect),
            icon: const Icon(Icons.add_to_drive),
            label: const Text('Collega Google Drive'),
          ),
        ),
      ]);
    } else {
      children.addAll([
        ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(account),
          subtitle: const Text('Cartella "Mirai Cook backup"'),
        ),
        // DATA-11
        ListTile(
          key: const Key('last-backup'),
          leading: const Icon(Icons.cloud_done_outlined),
          title: Text(
            lastBackup == null
                ? 'Nessun backup ancora'
                : 'Ultimo backup: '
                      '${formatDateTime(DateTime.parse(lastBackup))}',
          ),
          subtitle: lastError == null
              ? null
              : Text(
                  'Ultimo tentativo fallito: $lastError',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
        ),
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Fai un backup ora'),
          enabled: !_busy,
          onTap: () => _run(() async {
            final outcome = await controller.backupNow();
            if (!mounted) return;
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text(switch (outcome) {
                  BackupDone() => 'Backup completato',
                  BackupFailed(:final message) =>
                    'Backup non riuscito: $message',
                  BackupSkipped(:final reason) => reason,
                }),
              ),
            );
          }),
        ),
        // DATA-7
        ListTile(
          leading: const Icon(Icons.layers_outlined),
          title: const Text('Backup da conservare'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Conserva meno backup',
                icon: const Icon(Icons.remove),
                onPressed: keep > 1
                    ? () => settings.set(
                        SettingKeys.backupKeepCount,
                        '${keep - 1}',
                      )
                    : null,
              ),
              Text('$keep', key: const Key('keep-count')),
              IconButton(
                tooltip: 'Conserva più backup',
                icon: const Icon(Icons.add),
                onPressed: () =>
                    settings.set(SettingKeys.backupKeepCount, '${keep + 1}'),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Ripristina da Drive'),
          enabled: !_busy,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<bool>(builder: (_) => const RestoreScreen()),
          ),
        ),
        // DATA-16
        FutureBuilder<bool>(
          future: controller.canUndoRestore(),
          builder: (context, snap) => snap.data == true
              ? ListTile(
                  leading: const Icon(Icons.undo),
                  title: const Text('Annulla l\'ultimo ripristino'),
                  subtitle: const Text(
                    'Torna ai dati che avevi prima del ripristino',
                  ),
                  enabled: !_busy,
                  onTap: () => _run(() async {
                    final outcome = await controller.undoRestore();
                    if (mounted) {
                      await showRestoreOutcome(this.context, outcome);
                    }
                  }),
                )
              : const SizedBox.shrink(),
        ),
        // DATA-17
        ListTile(
          leading: const Icon(Icons.link_off),
          title: const Text('Scollega account'),
          subtitle: const Text('I backup già su Drive non vengono eliminati'),
          enabled: !_busy,
          onTap: () => _run(controller.disconnect),
        ),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
