import 'dart:io';

import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../application/ports/backup.dart';
import 'app_database.dart';

/// [LocalDatabase] adapter on the Drift/SQLite database.
class DriftLocalDatabase implements LocalDatabase {
  DriftLocalDatabase(this.db);

  final AppDatabase db;

  @override
  int get schemaVersion => db.schemaVersion;

  /// `VACUUM INTO`, never a copy of the live file (DATA-5).
  @override
  Future<void> snapshotTo(File file) =>
      db.customStatement('VACUUM INTO ?', [file.path]);

  @override
  SnapshotValidation validateSnapshot(File file) {
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

  @override
  Future<int> recipeCount() async {
    final count = db.recipes.id.count();
    final row = await (db.selectOnly(
      db.recipes,
    )..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Stream<void> get dataChanges => db
      .tableUpdates(const TableUpdateQuery.any())
      .where(
        (updates) => updates.any((u) => u.table != db.settings.actualTableName),
      );
}
