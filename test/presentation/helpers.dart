import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:mirai_cook/application/providers.dart';
import 'package:mirai_cook/data/db/app_database.dart';
import 'package:mirai_cook/presentation/app.dart';

import '../fakes.dart';

/// Thursday 5 November 2026; the week is 2–8 Nov.
final testNow = DateTime(2026, 11, 5, 12);

class TestApp {
  TestApp(this.db, this.clock, this.http, this.share);

  final AppDatabase db;
  final FixedClock clock;
  final FakeHttpClient http;
  final FakeShareIntentSource share;
}

/// Runs a widget test against the full app with an in-memory database and
/// a fixed clock, cleaning up Drift timers before the binding checks them.
@isTest
void appTest(
  String description,
  Future<void> Function(WidgetTester tester, TestApp app) body, {
  Widget? home,
  Future<void> Function(AppDatabase db)? seed,
}) {
  testWidgets(description, (tester) async {
    // Tall viewport so the whole week is built without scrolling.
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final app = await _pumpApp(tester, home: home, seed: seed);
    try {
      await body(tester, app);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(app.db.close);
    }
  });
}

Future<TestApp> _pumpApp(
  WidgetTester tester, {
  Widget? home,
  Future<void> Function(AppDatabase db)? seed,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  // Seed before any stream query exists: several writes inside one
  // runAsync can deadlock against stream re-queries in the fake zone.
  if (seed != null) await tester.runAsync(() => seed(db));
  final clock = FixedClock(testNow);
  final http = FakeHttpClient();
  final share = FakeShareIntentSource();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        httpClientProvider.overrideWithValue(http),
        thumbnailerProvider.overrideWithValue(FakeThumbnailer()),
        shareIntentSourceProvider.overrideWithValue(share),
      ],
      child: MiraiCookApp(home: home),
    ),
  );
  await settle(tester);
  return TestApp(db, clock, http, share);
}

/// Lets Drift stream queries deliver and animations finish. Uses bounded
/// pumps because a focused text field's cursor never "settles".
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 200));
  }
}
