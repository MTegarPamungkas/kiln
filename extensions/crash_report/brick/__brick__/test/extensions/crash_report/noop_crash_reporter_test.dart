import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/crash_report/noop_crash_reporter.dart';

void main() {
  group('NoopCrashReporter', () {
    test('every method completes without effect', () async {
      const reporter = NoopCrashReporter();

      await reporter.captureError(StateError('boom'));
      await reporter.captureMessage('Something happened');
      await reporter.addBreadcrumb('Opened profile');
      await reporter.setUser('user-1');
      await reporter.setContext('app', <String, Object?>{'flavor': 'prod'});

      expect(true, isTrue);
    });
  });
}
