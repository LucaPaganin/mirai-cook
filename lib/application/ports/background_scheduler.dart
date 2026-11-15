/// Schedules periodic background work (DATA-4).
abstract interface class BackgroundScheduler {
  Future<void> scheduleDailyBackup();
}
