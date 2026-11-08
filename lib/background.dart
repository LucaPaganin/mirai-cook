import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'application/providers.dart';

/// Entry point for the daily background backup (DATA-4).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    final container = ProviderContainer();
    try {
      await container.read(backupControllerProvider).backupIfNeeded();
    } finally {
      container.dispose();
    }
    // Failures are recorded and retried at the next trigger (DATA-11).
    return true;
  });
}
