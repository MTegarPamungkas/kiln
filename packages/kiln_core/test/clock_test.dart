import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  group('FixedClock', () {
    test('returns a controllable time', () {
      final clock = FixedClock.at(2026, 11, 1, 9);

      expect(clock.now(), DateTime(2026, 11, 1, 9));
    });

    test('set and advance move the clock', () {
      final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));

      clock.set(DateTime.utc(2026, 11, 2));
      expect(clock.now(), DateTime.utc(2026, 11, 2));

      clock.advance(const Duration(hours: 3));
      expect(clock.now(), DateTime.utc(2026, 11, 2, 3));
    });

    test('SystemClock returns a current time', () {
      final before = DateTime.now();
      final value = const SystemClock().now();
      final after = DateTime.now();

      expect(value.isBefore(before), isFalse);
      expect(value.isAfter(after), isFalse);
    });
  });
}
