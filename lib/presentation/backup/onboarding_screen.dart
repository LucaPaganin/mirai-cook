import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../data/repositories.dart';
import 'restore_screen.dart';

/// DATA-14: first launch with an empty database.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _startFresh() async {
    await ref
        .read(settingsRepositoryProvider)
        .set(SettingKeys.onboardingDone, '1');
    ref.invalidate(needsOnboardingProvider);
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(backupControllerProvider).connect();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<bool>(builder: (_) => const RestoreScreen()),
      );
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Benvenuto in Mirai Cook',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Hai già usato Mirai Cook su un altro telefono? Puoi '
                'ripristinare i tuoi dati da Google Drive.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _busy ? null : _restore,
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Ripristina da Google Drive'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('start-fresh'),
                onPressed: _busy ? null : _startFresh,
                child: const Text('Inizia da zero'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
