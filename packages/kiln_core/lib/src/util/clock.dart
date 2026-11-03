/// A source of time that can be replaced in tests.
abstract interface class Clock {
  DateTime now();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// A clock whose time only changes when the test moves it.
final class FixedClock implements Clock {
  FixedClock(DateTime value) : _value = value;

  factory FixedClock.at(int year, int month, int day, [int hour = 0]) {
    return FixedClock(DateTime(year, month, day, hour));
  }

  DateTime _value;

  @override
  DateTime now() => _value;

  void set(DateTime value) {
    _value = value;
  }

  void advance(Duration duration) {
    _value = _value.add(duration);
  }
}
