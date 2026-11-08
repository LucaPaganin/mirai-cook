/// A calendar date without time or time zone.
class CalendarDate implements Comparable<CalendarDate> {
  const CalendarDate(this.year, this.month, this.day);

  factory CalendarDate.fromDateTime(DateTime dt) =>
      CalendarDate(dt.year, dt.month, dt.day);

  /// Parses the compact integer form `yyyymmdd` used for storage.
  factory CalendarDate.fromInt(int value) =>
      CalendarDate(value ~/ 10000, (value ~/ 100) % 100, value % 100);

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// ISO weekday: 1 = Monday ... 7 = Sunday.
  int get weekday => _utc.weekday;

  int toInt() => year * 10000 + month * 100 + day;

  CalendarDate addDays(int days) =>
      CalendarDate.fromDateTime(_utc.add(Duration(days: days)));

  int daysUntil(CalendarDate other) => other._utc.difference(_utc).inDays;

  @override
  int compareTo(CalendarDate other) => toInt().compareTo(other.toInt());

  bool isBefore(CalendarDate other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is CalendarDate && other.toInt() == toInt();

  @override
  int get hashCode => toInt();

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// A Monday-to-Sunday week (PLAN-14).
class Week {
  Week.containing(CalendarDate date)
    : monday = date.addDays(-(date.weekday - DateTime.monday));

  final CalendarDate monday;

  CalendarDate get sunday => monday.addDays(6);

  List<CalendarDate> get days =>
      List.generate(7, (i) => monday.addDays(i), growable: false);

  Week get previous => Week.containing(monday.addDays(-7));
  Week get next => Week.containing(monday.addDays(7));

  bool contains(CalendarDate date) =>
      !date.isBefore(monday) && !sunday.isBefore(date);

  @override
  bool operator ==(Object other) => other is Week && other.monday == monday;

  @override
  int get hashCode => monday.hashCode;

  @override
  String toString() => 'Week($monday)';
}
