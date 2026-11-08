import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/data/db/drift_repositories.dart';
import 'package:mirai_cook/domain/calendar.dart';
import 'package:mirai_cook/domain/meal.dart';
import 'package:mirai_cook/domain/recipe.dart';

import 'helpers.dart';

const thursday = CalendarDate(2026, 11, 5);
final thuLunch = SlotId(thursday, MealType.lunch);
Finder slotFinder(SlotId s) =>
    find.byKey(Key('slot-${s.date.toInt()}-${s.meal.name}'));

void main() {
  // Covers: PLAN-1, PLAN-2, PLAN-13, PLAN-14
  appTest('home shows the clock week, Monday first, three meals a day', (
    tester,
    app,
  ) async {
    expect(find.text('2 nov – 8 nov'), findsOneWidget);
    expect(find.text('Lunedì 2 nov'), findsOneWidget);
    expect(find.text('Colazione'), findsWidgets);
    expect(find.text('Pranzo'), findsWidgets);
    expect(find.text('Cena'), findsWidgets);
  });

  // Covers: PLAN-4
  appTest('swiping changes week', (tester, app) async {
    await tester.fling(
      find.byKey(const Key('week-pager')),
      const Offset(-500, 0),
      2000,
    );
    await settle(tester);
    expect(find.text('9 nov – 15 nov'), findsOneWidget);
    await tester.fling(
      find.byKey(const Key('week-pager')),
      const Offset(500, 0),
      2000,
    );
    await tester.fling(
      find.byKey(const Key('week-pager')),
      const Offset(500, 0),
      2000,
    );
    await settle(tester);
    expect(find.text('26 ott – 1 nov'), findsOneWidget);
  });

  // Covers: PLAN-5, PLAN-7, PLAN-8
  appTest('tap slot, type, confirm: free text saved in one tap', (
    tester,
    app,
  ) async {
    await tester.tap(slotFinder(thuLunch)); // tap 1
    await settle(tester);
    final field = tester.widget<TextField>(find.byKey(const Key('slot-field')));
    expect(field.autofocus, isTrue);
    await tester.enterText(find.byKey(const Key('slot-field')), 'Pizza');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(find.byKey(const Key('slot-field')), findsNothing);
    expect(
      find.descendant(of: slotFinder(thuLunch), matching: find.text('Pizza')),
      findsOneWidget,
    );
  });

  // Covers: PLAN-6, PLAN-8, PLAN-12, PLAN-17, PLAN-18
  appTest('selecting a recipe suggestion takes two taps', (tester, app) async {
    await tester.runAsync(
      () =>
          DriftRecipeRepository(app.db)
              .save(const Recipe(title: 'Lasagna', servings: 6)),
    );
    await settle(tester);

    await tester.tap(slotFinder(thuLunch)); // tap 1
    await settle(tester);
    await tester.enterText(find.byKey(const Key('slot-field')), 'las');
    await settle(tester);
    await tester.tap(find.byKey(const Key('suggestion-Lasagna'))); // tap 2
    await settle(tester);
    expect(
      find.descendant(of: slotFinder(thuLunch), matching: find.text('Lasagna')),
      findsOneWidget,
      reason: 'default servings 1 -> no ×N badge',
    );

    // Raise servings from the sheet: the badge appears.
    await tester.tap(slotFinder(thuLunch));
    await settle(tester);
    await tester.tap(find.byTooltip('Più porzioni'));
    await settle(tester);
    await tester.tapAt(const Offset(10, 10)); // close sheet
    await settle(tester);
    expect(
      find.descendant(
        of: slotFinder(thuLunch),
        matching: find.text('Lasagna ×2'),
      ),
      findsOneWidget,
    );
  });

  // Covers: PLAN-16
  appTest('swiping an item in the sheet removes it', (tester, app) async {
    await tester.runAsync(
      () =>
          DriftPlanRepository(app.db)
              .addItem(thuLunch, const FreeTextItem('Pane')),
    );
    await settle(tester);
    await tester.tap(slotFinder(thuLunch));
    await settle(tester);
    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await settle(tester);
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
    expect(
      find.descendant(of: slotFinder(thuLunch), matching: find.text('Pane')),
      findsNothing,
    );
  });

  // Covers: PLAN-11
  appTest(
    'duplicating onto a non-empty week asks for confirmation',
    seed: (db) async {
      final plan = DriftPlanRepository(db);
      await plan.addItem(
        SlotId(const CalendarDate(2026, 10, 29), MealType.lunch),
        const FreeTextItem('Risotto'),
      );
      await plan.addItem(thuLunch, const FreeTextItem('Pizza'));
    },
    (tester, app) async {
      await tester.tap(find.byType(PopupMenuButton<String>));
      await settle(tester);
      await tester.tap(find.text('Duplica settimana precedente'));
      await settle(tester);
      expect(find.text('Sovrascrivere la settimana?'), findsOneWidget);
      await tester.tap(find.text('Sovrascrivi'));
      await settle(tester);
      expect(
        find.descendant(
          of: slotFinder(thuLunch),
          matching: find.text('Risotto'),
        ),
        findsOneWidget,
      );
    },
  );

  // Covers: PLAN-16
  appTest(
    'the bin button in the sheet removes one item',
    seed: (db) async {
      final plan = DriftPlanRepository(db);
      await plan.addItem(thuLunch, const FreeTextItem('Pane'));
      await plan.addItem(thuLunch, const FreeTextItem('Insalata'));
    },
    (tester, app) async {
      await tester.tap(slotFinder(thuLunch));
      await settle(tester);
      await tester.tap(find.byKey(const Key('remove-item-0')));
      await settle(tester);
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
      expect(
        find.descendant(of: slotFinder(thuLunch), matching: find.text('Pane')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: slotFinder(thuLunch),
          matching: find.text('Insalata'),
        ),
        findsOneWidget,
      );
    },
  );

  // Covers: PLAN-9
  appTest(
    'long press offers to clear the whole meal',
    seed: (db) async {
      final plan = DriftPlanRepository(db);
      await plan.addItem(thuLunch, const FreeTextItem('Pane'));
      await plan.addItem(thuLunch, const FreeTextItem('Insalata'));
    },
    (tester, app) async {
      await tester.longPress(slotFinder(thuLunch));
      await settle(tester);
      await tester.tap(find.text('Svuota pasto'));
      await settle(tester);
      expect(
        find.descendant(of: slotFinder(thuLunch), matching: find.text('—')),
        findsOneWidget,
      );
    },
  );

  // Covers: PLAN-19
  appTest(
    'typing a recipe title links the recipe',
    seed: (db) =>
        DriftRecipeRepository(db)
            .save(const Recipe(title: 'Lasagna', servings: 6)),
    (tester, app) async {
      await tester.tap(slotFinder(thuLunch));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('slot-field')), ' lasagna ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      final slots = (await tester.runAsync(
        () => DriftPlanRepository(app.db).getRange(thursday, thursday),
      ))!;
      expect(slots[thuLunch]!.single, isA<RecipeItem>());
      expect(
        find.descendant(
          of: slotFinder(thuLunch),
          matching: find.text('Lasagna'),
        ),
        findsOneWidget,
      );
    },
  );
}
