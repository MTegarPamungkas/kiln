import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/crash_report/error_deduplicator.dart';

void main() {
  group('ErrorDeduplicator', () {
    test('collapses identical errors within the window', () async {
      final clock = FixedClock(DateTime(2020));
      final fake = FakeCrashReporter();
      final dedup = ErrorDeduplicator(
        delegate: fake,
        clock: clock,
        window: const Duration(seconds: 60),
      );
      final error = StateError('boom');

      await dedup.captureError(error);
      clock.advance(const Duration(seconds: 10));
      await dedup.captureError(error);
      clock.advance(const Duration(seconds: 10));
      await dedup.captureError(error);

      expect(fake.errors, hasLength(1));
    });

    test('reports again once the window passes', () async {
      final clock = FixedClock(DateTime(2020));
      final fake = FakeCrashReporter();
      final dedup = ErrorDeduplicator(
        delegate: fake,
        clock: clock,
        window: const Duration(seconds: 60),
      );

      await dedup.captureError(StateError('boom'));
      clock.advance(const Duration(seconds: 61));
      await dedup.captureError(StateError('boom'));

      expect(fake.errors, hasLength(2));
    });

    test('distinct errors are both reported', () async {
      final fake = FakeCrashReporter();
      final dedup = ErrorDeduplicator(
        delegate: fake,
        clock: FixedClock(DateTime(2020)),
      );

      await dedup.captureError(StateError('a'));
      await dedup.captureError(StateError('b'));

      expect(fake.errors, hasLength(2));
    });

    test('disabled forwards every error', () async {
      final fake = FakeCrashReporter();
      final dedup = ErrorDeduplicator(
        delegate: fake,
        clock: FixedClock(DateTime(2020)),
        enabled: false,
      );
      final error = StateError('boom');

      await dedup.captureError(error);
      await dedup.captureError(error);

      expect(fake.errors, hasLength(2));
    });

    test('messages and breadcrumbs always forward', () async {
      final fake = FakeCrashReporter();
      final dedup = ErrorDeduplicator(
        delegate: fake,
        clock: FixedClock(DateTime(2020)),
      );

      await dedup.captureMessage('x');
      await dedup.captureMessage('x');
      await dedup.addBreadcrumb('b');
      await dedup.addBreadcrumb('b');

      expect(fake.messages, hasLength(2));
      expect(fake.breadcrumbs, hasLength(2));
    });
  });
}
