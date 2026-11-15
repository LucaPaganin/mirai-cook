import 'package:workmanager/workmanager.dart';

import '../../application/ports/background_scheduler.dart';

/// [BackgroundScheduler] adapter on `workmanager`.
class WorkmanagerScheduler implements BackgroundScheduler {
  WorkmanagerScheduler(this._dispatcher);

  static const dailyBackupTask = 'daily-backup';

  final Function _dispatcher;

  @override
  Future<void> scheduleDailyBackup() async {
    await Workmanager().initialize(_dispatcher);
    await Workmanager().registerPeriodicTask(
      dailyBackupTask,
      dailyBackupTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
