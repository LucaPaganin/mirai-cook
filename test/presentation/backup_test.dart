import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/data/backup/backup_target.dart';
import 'package:mirai_cook/data/db/drift_repositories.dart';
import 'package:mirai_cook/data/repositories.dart';
import 'package:mirai_cook/domain/recipe.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'helpers.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Impostazioni'));
  await settle(tester);
}

bool badgeVisible(WidgetTester tester) => tester
    .widget<Badge>(find.byKey(const Key('settings-badge')))
    .isLabelVisible;

void main() {
  // Covers: DATA-12, DATA-13
  appTest('warns until Drive is connected, then shows the account', (
    tester,
    app,
  ) async {
    expect(badgeVisible(tester), isTrue);
    await openSettings(tester);
    expect(find.byKey(const Key('backup-warning')), findsOneWidget);

    await tester.tap(find.byKey(const Key('connect-drive')));
    await settle(tester);
    expect(app.account.connected, isTrue);
    expect(find.text('cuoco@example.com'), findsOneWidget);
    expect(find.byKey(const Key('backup-warning')), findsNothing);
    expect(badgeVisible(tester), isFalse);
    expect(find.text('Nessun backup ancora'), findsOneWidget);
    expect(find.text('10'), findsOneWidget); // DATA-7 default
  });

  // Covers: DATA-4
  appTest('connecting schedules the daily background backup', (
    tester,
    app,
  ) async {
    expect(app.scheduler.scheduled, 0);
    await openSettings(tester);
    await tester.tap(find.byKey(const Key('connect-drive')));
    await settle(tester);
    expect(app.scheduler.scheduled, 1);
  });

  // Covers: DATA-4
  appTest(
    'an already connected app re-registers the daily task on start',
    seed: (db) =>
        DriftSettingsRepository(db)
            .set(SettingKeys.backupAccount, 'cuoco@example.com'),
    (tester, app) async {
      expect(app.scheduler.scheduled, 1);
    },
  );

  // Covers: DATA-17
  appTest('disconnecting keeps snapshots on Drive', (tester, app) async {
    await openSettings(tester);
    await tester.tap(find.byKey(const Key('connect-drive')));
    await settle(tester);
    app.target.files['x'] = (
      SnapshotInfo(id: 'x', name: 'x', createdAt: DateTime.utc(2026)),
      const <int>[],
    );
    await tester.tap(find.text('Scollega account'));
    await settle(tester);
    expect(app.account.connected, isFalse);
    expect(app.target.files, hasLength(1));
    expect(find.byKey(const Key('backup-warning')), findsOneWidget);
  });

  // Covers: DATA-14
  appTest(
    'an empty first launch offers restore or a fresh start',
    onboarded: false,
    (tester, app) async {
      expect(find.text('Ripristina da Google Drive'), findsOneWidget);
      await tester.tap(find.byKey(const Key('start-fresh')));
      await settle(tester);
      expect(find.text('Piano'), findsOneWidget);
    },
  );

  // Covers: DATA-14
  appTest(
    'no onboarding when the database already has data',
    onboarded: false,
    seed: (db) =>
        DriftRecipeRepository(db)
            .save(const Recipe(title: 'Pesto', servings: 2)),
    (tester, app) async {
      expect(find.text('Ripristina da Google Drive'), findsNothing);
      expect(find.text('Piano'), findsOneWidget);
    },
  );

  // Covers: DATA-10, DATA-15
  appTest('a snapshot from a newer app version is refused with a reason', (
    tester,
    app,
  ) async {
    final bytes = (await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('mc');
      final f = File('${dir.path}/new.sqlite');
      final conn = sqlite.sqlite3.open(f.path)
        ..execute('CREATE TABLE recipes (id INTEGER)')
        ..execute('CREATE TABLE slot_items (id INTEGER)')
        ..execute('CREATE TABLE settings (key TEXT)')
        ..execute('PRAGMA user_version = 99');
      conn.close();
      final b = await f.readAsBytes();
      await dir.delete(recursive: true);
      return b;
    }))!;
    app.target.files['new'] = (
      SnapshotInfo(
        id: 'new',
        name: 'new.sqlite',
        createdAt: DateTime.utc(2026, 11, 4, 9, 30),
        recipeCount: 42,
      ),
      bytes,
    );

    await openSettings(tester);
    await tester.tap(find.byKey(const Key('connect-drive')));
    await settle(tester);
    await tester.tap(find.text('Ripristina da Drive'));
    await settle(tester);
    expect(find.text('42 ricette'), findsOneWidget);
    await tester.tap(find.text('42 ricette'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Ripristina'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await settle(tester);
    }
    expect(find.text('Backup non compatibile'), findsOneWidget);
    expect(find.textContaining('versione più recente'), findsOneWidget);
    expect(
      await tester.runAsync(
        () => DriftSettingsRepository(app.db).get(SettingKeys.backupAccount),
      ),
      'cuoco@example.com',
      reason: 'current data untouched',
    );
  });
}
