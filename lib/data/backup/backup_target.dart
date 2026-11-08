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
