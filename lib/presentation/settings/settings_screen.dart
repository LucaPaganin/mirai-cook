import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../data/repositories.dart';
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
        ],
      ),
    );
  }
}
