import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  group('Debouncer', () {
    test('runs only the last action after calls stop', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 20));
      var value = 0;

      debouncer.run(() => value = 1);
      debouncer.run(() => value = 2);
      debouncer.run(() => value = 3);

      expect(debouncer.isPending, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(value, 3);
      expect(debouncer.isPending, isFalse);
      debouncer.dispose();
    });

    test('cancel prevents the pending action', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 20));
      var called = false;

      debouncer.run(() => called = true);
      debouncer.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(called, isFalse);
      expect(debouncer.isPending, isFalse);
      debouncer.dispose();
    });

    test('call is an alias for run', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 10));
      var called = false;

      debouncer(() => called = true);
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(called, isTrue);
      debouncer.dispose();
    });
  });
}
