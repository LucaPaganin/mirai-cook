/// Source of the current time. The only implementation allowed to call
/// `DateTime.now()` is `SystemClock` in the data layer.
abstract interface class Clock {
  DateTime now();
}
