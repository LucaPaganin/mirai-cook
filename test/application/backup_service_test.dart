import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/application/backup_service.dart';
import 'package:mirai_cook/data/db/app_database.dart';
import 'package:mirai_cook/data/db/drift_repositories.dart';
import 'package:mirai_cook/data/repositories.dart';
import 'package:mirai_cook/domain/recipe.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../fakes.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftSettingsRepository settings;
  late DriftRecipeRepository recipes;
  late FixedClock clock;
  late TempDatabaseFiles files;
  late FakeBackupTarget target;
  late BackupService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settings = DriftSettingsRepository(db);
    recipes = DriftRecipeRepository(db);
    clock = FixedClock(DateTime.utc(2026, 11, 5, 10));
    files = TempDatabaseFiles();
    target = FakeBackupTarget();
    service = BackupService(
      db: db,
      settings: settings,
      clock: clock,
      files: files,
    );
    await settings.set(SettingKeys.backupAccount, 'cuoco@example.com');
  });

  tearDown(() async {
    await db.close();
    files.dispose();
  });

  Future<void> change() async {
    await recipes.save(const Recipe(title: 'Pesto', servings: 2));
    await service.markChanged();
  }

  void tick([Duration d = const Duration(minutes: 1)]) =>
      clock.value = clock.value.add(d);

  // Covers: DATA-12
  test('does nothing until an account is connected', () async {
    await settings.set(SettingKeys.backupAccount, null);
    await change();
    expect(await service.backupIfNeeded(target), isA<BackupSkipped>());
    expect(target.files, isEmpty);
  });

  // Covers: DATA-3
  test('backs up only when data changed since the last backup', () async {
    expect(await service.backupIfNeeded(target), isA<BackupSkipped>());
    await change();
    expect(await service.hasPendingChanges(), isTrue);
    tick();
    expect(await service.backupIfNeeded(target), isA<BackupDone>());
    expect(await service.hasPendingChanges(), isFalse);
    expect(await service.backupIfNeeded(target), isA<BackupSkipped>());
    tick();
    await change();
    expect(await service.hasPendingChanges(), isTrue);
  });

  // Covers: DATA-3
  test('ChangeTracker marks writes to data tables, not settings', () async {
    final tracker = ChangeTracker(db, service)..start();
    addTearDown(tracker.stop);
    await settings.set('x', '1');
    await pumpEventQueue();
    expect(await settings.get(SettingKeys.lastChangeAt), isNull);
    await recipes.save(const Recipe(title: 'Pesto', servings: 2));
    await pumpEventQueue();
    expect(await settings.get(SettingKeys.lastChangeAt), isNotNull);
  });

  // Covers: DATA-5, DATA-6, DATA-15
  test('uploads a consistent VACUUM INTO snapshot with metadata', () async {
    await change();
    final outcome = await service.backup(target);
    expect(outcome, isA<BackupDone>());
    final (info, bytes) = target.files.values.single;
    expect(info.name, 'mirai-cook-20261105-100000.sqlite');
    expect(info.recipeCount, 1);
    expect(info.schemaVersion, db.schemaVersion);
    expect(info.createdAt, clock.value);

    final f = File('${files.root.path}/check.sqlite')..writeAsBytesSync(bytes);
    final conn = sqlite.sqlite3.open(f.path);
    addTearDown(conn.close);
    expect(conn.select('SELECT title FROM recipes').single['title'], 'Pesto');
    expect(
      conn.select('PRAGMA user_version').single.values.single,
      db.schemaVersion,
    );
  });

  // Covers: DATA-7
  test('keeps only the newest N snapshots', () async {
    await settings.set(SettingKeys.backupKeepCount, '3');
    for (var i = 0; i < 5; i++) {
      tick(const Duration(hours: 1));
      await service.backup(target);
    }
    final kept = await target.list();
    expect(kept, hasLength(3));
    expect(kept.first.createdAt, clock.value);
  });

  // Covers: DATA-7
  test('default retention is 10', () async {
    expect(await service.keepCount(), 10);
  });

  // Covers: DATA-11
  test('a failed upload is recorded and retried next time', () async {
    await change();
    tick();
    target.failWith = const SocketException('offline');
    expect(await service.backupIfNeeded(target), isA<BackupFailed>());
    expect(
      await settings.get(SettingKeys.lastBackupError),
      contains('offline'),
    );
    expect(await settings.get(SettingKeys.lastBackupAt), isNull);
    expect(await service.hasPendingChanges(), isTrue);

    target.failWith = null;
    tick();
    expect(await service.backupIfNeeded(target), isA<BackupDone>());
    expect(await settings.get(SettingKeys.lastBackupError), isNull);
    expect(
      await settings.get(SettingKeys.lastBackupAt),
      clock.value.toIso8601String(),
    );
  });

  // Covers: DATA-11
  test('missing Drive access counts as a failure', () async {
    await change();
    expect(await service.backupIfNeeded(null), isA<BackupFailed>());
  });

  group('restore', () {
    Future<File?> runRestore(File file) async {
      File? replaced;
      final outcome = await service.restoreFile(file, (f) async {
        replaced = f;
      });
      if (outcome is RestoreDone) {
        expect(await outcome.safetySnapshot.exists(), isTrue);
      }
      return replaced;
    }

    // Covers: DATA-8, DATA-16
    test('valid snapshot replaces the database after a safety copy', () async {
      await change();
      await service.backup(target);
      final snapshot = (await target.list()).single;
      File? replaced;
      final outcome = await service.restore(target, snapshot, (f) async {
        replaced = f;
        // The replacer receives a valid copy of the snapshot.
        final restored = AppDatabase(NativeDatabase(f));
        final r = await DriftRecipeRepository(restored).watchAll().first;
        expect(r.single.title, 'Pesto');
        await restored.close();
      });
      expect(outcome, isA<RestoreDone>());
      expect(replaced, isNotNull);
      expect(await service.listLocalSnapshots(), hasLength(1));
    });

    // Covers: DATA-16
    test('keeps at most 3 local safety snapshots', () async {
      for (var i = 0; i < 5; i++) {
        tick(const Duration(seconds: 1));
        await service.createLocalSnapshot();
      }
      expect(await service.listLocalSnapshots(), hasLength(3));
    });

    // Covers: DATA-10
    test('refuses a snapshot from a newer schema', () async {
      final f = File('${files.root.path}/new.sqlite');
      final conn = sqlite.sqlite3.open(f.path);
      conn.execute('CREATE TABLE recipes (id INTEGER)');
      conn.execute('CREATE TABLE slot_items (id INTEGER)');
      conn.execute('CREATE TABLE settings (key TEXT)');
      conn.execute('PRAGMA user_version = 99');
      conn.close();
      expect(service.validate(f), isA<SnapshotTooNew>());
      expect(await runRestore(f), isNull);
    });

    // Covers: DATA-8
    test('refuses garbage and foreign databases', () async {
      final garbage = File('${files.root.path}/garbage.sqlite')
        ..writeAsStringSync('not a database at all');
      expect(service.validate(garbage), isA<SnapshotInvalid>());
      expect(await runRestore(garbage), isNull);

      final foreign = File('${files.root.path}/foreign.sqlite');
      final conn = sqlite.sqlite3.open(foreign.path);
      conn.execute('CREATE TABLE things (id INTEGER)');
      conn.execute('PRAGMA user_version = 1');
      conn.close();
      expect(service.validate(foreign), isA<SnapshotInvalid>());
    });

    // Covers: DATA-9
    test('accepts snapshots with an older or equal schema version', () async {
      await service.backup(target);
      final f = File('${files.root.path}/same.sqlite')
        ..writeAsBytesSync(target.files.values.single.$2);
      expect(service.validate(f), isA<SnapshotValid>());
    });
  });
}
