import 'package:workmanager/workmanager.dart';

/// Schedules periodic background work (DATA-4).
abstract interface class BackgroundScheduler {
  Future<void> scheduleDailyBackup();
}

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
