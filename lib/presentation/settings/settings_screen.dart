import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../data/repositories.dart';
import '../backup/backup_section.dart';
import '../common/format.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servings = ref.watch(defaultServingsProvider).value ?? 1;
    final settings = ref.read(settingsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        children: [
          // UI-1
          ListTile(
            title: const Text('Tema'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<ThemeMode>(
                key: const Key('theme-mode'),
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('Sistema'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Chiaro'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Scuro'),
                  ),
                ],
                selected: {
                  ref.watch(themeModeProvider).value ?? ThemeMode.system,
                },
                onSelectionChanged: (s) => settings.set(
                  SettingKeys.themeMode,
                  s.single == ThemeMode.system ? null : s.single.name,
                ),
              ),
            ),
          ),
          // PLAN-18
          ListTile(
            title: const Text('Porzioni predefinite'),
            subtitle: const Text('Usate quando aggiungi una ricetta al piano'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Meno',
                  icon: const Icon(Icons.remove),
                  onPressed: servings > 1
                      ? () => settings.set(
                          SettingKeys.defaultServings,
                          '${servings.round() - 1}',
                        )
                      : null,
                ),
                Text(
                  formatNumber(servings),
                  key: const Key('default-servings'),
                ),
                IconButton(
                  tooltip: 'Più',
                  icon: const Icon(Icons.add),
                  onPressed: () => settings.set(
                    SettingKeys.defaultServings,
                    '${servings.round() + 1}',
                  ),
                ),
              ],
            ),
          ),
          const BackupSection(),
        ],
      ),
    );
  }
}
