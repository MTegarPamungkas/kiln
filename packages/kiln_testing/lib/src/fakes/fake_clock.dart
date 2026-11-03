import 'package:kiln_core/kiln_core.dart';

/// [Clock] whose time is moved manually by the test.
final class FakeClock implements Clock {
  FakeClock(DateTime value) : _value = value;

  factory FakeClock.at(int year, int month, int day, [int hour = 0]) {
    return FakeClock(DateTime(year, month, day, hour));
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
