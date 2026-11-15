import 'dart:io';

/// Metadata stored alongside each snapshot (DATA-15).
class SnapshotInfo {
  const SnapshotInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    this.recipeCount,
    this.schemaVersion,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int? recipeCount;
  final int? schemaVersion;
}

/// Remote storage for database snapshots (DATA-6). Implemented by Google
/// Drive; tests use an in-memory fake.
abstract interface class BackupTarget {
  /// Snapshots, newest first.
  Future<List<SnapshotInfo>> list();
  Future<void> upload(File file, SnapshotInfo info);
  Future<void> download(String id, File destination);
  Future<void> delete(String id);
}

/// The account that grants access to a [BackupTarget] (DATA-12, DATA-17).
abstract interface class BackupAccount {
  /// Interactive sign-in and consent; returns the account label (email).
  Future<String> connect();

  /// Revokes access; snapshots stay on Drive (DATA-17).
  Future<void> disconnect();

  /// A target using previously granted access, without UI; null if access
  /// is missing or expired and needs [connect].
  Future<BackupTarget?> silentTarget();
}

/// Where the database and local safety snapshots live.
abstract interface class DatabaseFiles {
  Future<File> databaseFile();
  Future<Directory> tempDirectory();
  Future<Directory> localSnapshotsDirectory();
}

sealed class SnapshotValidation {
  const SnapshotValidation();
}

class SnapshotValid extends SnapshotValidation {
  const SnapshotValid(this.schemaVersion);
  final int schemaVersion;
}

class SnapshotInvalid extends SnapshotValidation {
  const SnapshotInvalid(this.reason);
  final String reason;
}

/// DATA-10: made by a newer app version.
class SnapshotTooNew extends SnapshotValidation {
  const SnapshotTooNew(this.schemaVersion, this.supported);
  final int schemaVersion;
  final int supported;
}

/// The live local database, as seen by the backup use case. Implemented by
/// the Drift adapter, so [BackupService] knows nothing about SQLite.
abstract interface class LocalDatabase {
  int get schemaVersion;

  /// Writes a consistent copy of the live database to [file] (DATA-5).
  Future<void> snapshotTo(File file);

  /// Checks integrity, expected tables and schema version of a snapshot
  /// file (DATA-8, DATA-10).
  SnapshotValidation validateSnapshot(File file);

  Future<int> recipeCount();

  /// Emits whenever user data (anything but settings) is written (DATA-3).
  Stream<void> get dataChanges;
}
