import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/domain/calendar.dart';

void main() {
  // Covers: PLAN-14, PLAN-1
  group('Week starts on Monday', () {
    for (final (date, monday) in [
      (const CalendarDate(2026, 11, 2), const CalendarDate(2026, 11, 2)),
      (const CalendarDate(2026, 11, 5), const CalendarDate(2026, 11, 2)),
      (const CalendarDate(2026, 11, 8), const CalendarDate(2026, 11, 2)),
      (const CalendarDate(2027, 1, 1), const CalendarDate(2026, 12, 28)),
      (const CalendarDate(2024, 3, 3), const CalendarDate(2024, 2, 26)),
    ]) {
      test('$date -> $monday', () {
        final week = Week.containing(date);
        expect(week.monday, monday);
        expect(week.days, hasLength(7));
        expect(week.days.first.weekday, DateTime.monday);
        expect(week.days.last.weekday, DateTime.sunday);
        expect(week.contains(date), isTrue);
      });
    }
  });

  // Covers: PLAN-4
  test('previous and next week', () {
    final w = Week.containing(const CalendarDate(2026, 11, 8));
    expect(w.previous.monday, const CalendarDate(2026, 10, 26));
    expect(w.next.monday, const CalendarDate(2026, 11, 9));
  });

  // Covers: PLAN-15
  test('CalendarDate round-trips through its storage int', () {
    const d = CalendarDate(2026, 3, 29);
    expect(d.toInt(), 20260329);
    expect(CalendarDate.fromInt(20260329), d);
    // DST change in Europe on 2026-03-29 must not break day arithmetic.
    expect(d.addDays(1), const CalendarDate(2026, 3, 30));
  });
}
