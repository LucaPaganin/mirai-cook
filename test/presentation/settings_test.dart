import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/data/db/drift_repositories.dart';
import 'package:mirai_cook/data/repositories.dart';

import 'helpers.dart';

void main() {
  // Covers: PLAN-18
  appTest('default servings start at 1 and can be changed', (
    tester,
    app,
  ) async {
    await tester.tap(find.text('Impostazioni'));
    await settle(tester);
    Text value() =>
        tester.widget<Text>(find.byKey(const Key('default-servings')));
    expect(value().data, '1');
    await tester.tap(find.byTooltip('Più'));
    await settle(tester);
    expect(value().data, '2');
    expect(
      await tester.runAsync(
        () => DriftSettingsRepository(app.db).get(SettingKeys.defaultServings),
      ),
      '2',
    );
  });
}
