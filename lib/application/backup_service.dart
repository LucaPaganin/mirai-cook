import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../data/backup/backup_target.dart';
import '../data/db/app_database.dart';
import '../data/repositories.dart';
import '../domain/clock.dart';

sealed class BackupOutcome {
  const BackupOutcome();
}

class BackupDone extends BackupOutcome {
  const BackupDone(this.at);
  final DateTime at;
}

class BackupSkipped extends BackupOutcome {
  const BackupSkipped(this.reason);
  final String reason;
}

class BackupFailed extends BackupOutcome {
  const BackupFailed(this.message);
  final String message;
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

sealed class RestoreOutcome {
  const RestoreOutcome();
}

class RestoreDone extends RestoreOutcome {
  const RestoreDone(this.safetySnapshot);

  /// Local copy of the database before the restore (DATA-16).
  final File safetySnapshot;
}

class RestoreRefused extends RestoreOutcome {
  const RestoreRefused(this.validation);
  final SnapshotValidation validation;
}

class RestoreFailed extends RestoreOutcome {
  const RestoreFailed(this.message);
  final String message;
}

/// Replaces the live database file with [source] and reopens it; the new
/// database runs migrations on open (DATA-9).
typedef DatabaseReplacer = Future<void> Function(File source);

/// Snapshot, upload, prune, validate and restore (DATA-3..11, DATA-16).
class BackupService {
  BackupService({
    required this.db,
    required this.settings,
    required this.clock,
    required this.files,
    this.keepLocalSnapshots = 3,
  });

  final AppDatabase db;
  final SettingsRepository settings;
  final Clock clock;
  final DatabaseFiles files;
  final int keepLocalSnapshots;

  static const defaultKeepCount = 10;

  Future<bool> isConfigured() async =>
      await settings.get(SettingKeys.backupAccount) != null;

  Future<int> keepCount() async =>
      int.tryParse(await settings.get(SettingKeys.backupKeepCount) ?? '') ??
      defaultKeepCount;

  /// True when data changed after the last successful backup (DATA-3).
  Future<bool> hasPendingChanges() async {
    final changed = DateTime.tryParse(
      await settings.get(SettingKeys.lastChangeAt) ?? '',
    );
    if (changed == null) return false;
    final backed = DateTime.tryParse(
      await settings.get(SettingKeys.lastBackupAt) ?? '',
    );
    return backed == null || changed.isAfter(backed);
  }

  /// Records a data change; called by [ChangeTracker].
  Future<void> markChanged() => settings.set(
    SettingKeys.lastChangeAt,
    clock.now().toUtc().toIso8601String(),
  );

  /// Consistent copy via `VACUUM INTO`, never a copy of the live file
  /// (DATA-5).
  Future<File> createSnapshot(Directory dir, String name) async {
    final file = File(p.join(dir.path, name));
    if (await file.exists()) await file.delete();
    await db.customStatement('VACUUM INTO ?', [file.path]);
    return file;
  }

  Future<BackupOutcome> backupIfNeeded(BackupTarget? target) async {
    if (!await isConfigured()) {
      return const BackupSkipped('Backup non configurato');
    }
    if (!await hasPendingChanges()) {
      return const BackupSkipped('Nessuna modifica');
    }
    if (target == null) {
      const message = 'Accesso a Google Drive non disponibile';
      await settings.set(SettingKeys.lastBackupError, message);
      return const BackupFailed(message);
    }
    return backup(target);
  }

  /// DATA-6, DATA-7, DATA-11. Failures are recorded and retried at the
  /// next trigger.
  Future<BackupOutcome> backup(BackupTarget target) async {
    final now = clock.now().toUtc();
    Directory? tmp;
    try {
      tmp = await files.tempDirectory();
      final name = 'mirai-cook-${_stamp(now)}.sqlite';
      final file = await createSnapshot(tmp, name);
      await target.upload(
        file,
        SnapshotInfo(
          id: '',
          name: name,
          createdAt: now,
          recipeCount: await _recipeCount(),
          schemaVersion: db.schemaVersion,
        ),
      );
      await _prune(target, await keepCount());
      await settings.set(SettingKeys.lastBackupAt, now.toIso8601String());
      await settings.set(SettingKeys.lastBackupError, null);
      return BackupDone(now);
    } on Object catch (e) {
      final message = '$e';
      await settings.set(SettingKeys.lastBackupError, message);
      return BackupFailed(message);
    } finally {
      if (tmp != null && await tmp.exists()) {
        await tmp.delete(recursive: true);
      }
    }
  }

  Future<void> _prune(BackupTarget target, int keep) async {
    final all = await target.list();
    for (final s in all.skip(keep)) {
      await target.delete(s.id);
    }
  }

  /// DATA-8, DATA-10: integrity, expected tables and schema version.
  SnapshotValidation validate(File file) {
    sqlite.Database? conn;
    try {
      conn = sqlite.sqlite3.open(file.path, mode: sqlite.OpenMode.readOnly);
      final integrity = conn
          .select('PRAGMA integrity_check')
          .first
          .values
          .first;
      if (integrity != 'ok') {
        return const SnapshotInvalid('Il file di backup è danneggiato');
      }
      final tables = conn
          .select("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((r) => r['name'] as String)
          .toSet();
      if (!tables.containsAll(['recipes', 'slot_items', 'settings'])) {
        return const SnapshotInvalid('Il file non è un backup di Mirai Cook');
      }
      final version =
          conn.select('PRAGMA user_version').first.values.first as int;
      if (version < 1) {
        return const SnapshotInvalid('Versione del backup sconosciuta');
      }
      if (version > db.schemaVersion) {
        return SnapshotTooNew(version, db.schemaVersion);
      }
      return SnapshotValid(version);
    } on Object {
      return const SnapshotInvalid('Il file non è un database valido');
    } finally {
      conn?.close();
    }
  }

  /// Downloads, validates, saves a local safety copy, then replaces the
  /// database (DATA-8, DATA-16).
  Future<RestoreOutcome> restore(
    BackupTarget target,
    SnapshotInfo snapshot,
    DatabaseReplacer replace,
  ) async {
    Directory? tmp;
    try {
      tmp = await files.tempDirectory();
      final file = File(p.join(tmp.path, 'restore.sqlite'));
      await target.download(snapshot.id, file);
      return await restoreFile(file, replace);
    } on Object catch (e) {
      return RestoreFailed('$e');
    } finally {
      if (tmp != null && await tmp.exists()) {
        await tmp.delete(recursive: true);
      }
    }
  }

  Future<RestoreOutcome> restoreFile(
    File file,
    DatabaseReplacer replace,
  ) async {
    final validation = validate(file);
    if (validation is! SnapshotValid) return RestoreRefused(validation);
    final safety = await createLocalSnapshot();
    await replace(file);
    return RestoreDone(safety);
  }

  Future<File> createLocalSnapshot() async {
    final dir = await files.localSnapshotsDirectory();
    final file = await createSnapshot(
      dir,
      'pre-restore-${_stamp(clock.now().toUtc())}.sqlite',
    );
    final all = await listLocalSnapshots();
    for (final old in all.skip(keepLocalSnapshots)) {
      await old.delete();
    }
    return file;
  }

  /// Local safety snapshots, newest first.
  Future<List<File>> listLocalSnapshots() async {
    final dir = await files.localSnapshotsDirectory();
    final list = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.sqlite'))
        .cast<File>()
        .toList();
    list.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    return list;
  }

  Future<int> _recipeCount() async {
    final count = db.recipes.id.count();
    final row = await (db.selectOnly(
      db.recipes,
    )..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  static String _stamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }
}

/// Marks data as changed whenever a non-settings table is written (DATA-3).
class ChangeTracker {
  ChangeTracker(this.db, this.service);

  final AppDatabase db;
  final BackupService service;
  StreamSubscription<Set<TableUpdate>>? _sub;

  void start() {
    _sub ??= db
        .tableUpdates(const TableUpdateQuery.any())
        .where(
          (updates) =>
              updates.any((u) => u.table != db.settings.actualTableName),
        )
        .listen((_) => service.markChanged());
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
