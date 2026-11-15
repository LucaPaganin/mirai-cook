import 'package:drift_flutter/drift_flutter.dart';

import '../../application/ports/backup.dart';
import 'app_database.dart';

/// Opens the on-device database at the path given by [files].
AppDatabase openAppDatabase(DatabaseFiles files) => AppDatabase(
  driftDatabase(
    name: 'mirai_cook',
    native: DriftNativeOptions(
      databasePath: () async => (await files.databaseFile()).path,
    ),
  ),
);
