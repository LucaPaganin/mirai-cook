import '../domain/clock.dart';

/// The only place allowed to read the system time.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
