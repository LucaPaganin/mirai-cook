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

  // Covers: UI-1, UI-2
  appTest('the theme follows the system by default and can be forced', (
    tester,
    app,
  ) async {
    ThemeMode mode() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
    expect(mode(), ThemeMode.system);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).darkTheme,
      isNotNull,
    );

    await tester.tap(find.text('Impostazioni'));
    await settle(tester);
    await tester.tap(find.text('Scuro'));
    await settle(tester);
    expect(mode(), ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Tema'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('Chiaro'));
    await settle(tester);
    expect(mode(), ThemeMode.light);

    await tester.tap(find.text('Sistema'));
    await settle(tester);
    expect(mode(), ThemeMode.system);
    expect(
      await tester.runAsync(
        () => DriftSettingsRepository(app.db).get(SettingKeys.themeMode),
      ),
      isNull,
    );
  });
}
