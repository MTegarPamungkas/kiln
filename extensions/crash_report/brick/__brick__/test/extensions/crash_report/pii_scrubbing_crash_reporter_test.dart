import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/crash_report/pii_scrubbing_crash_reporter.dart';

void main() {
  group('PiiScrubbingCrashReporter', () {
    test('redacts sensitive context values but keeps safe ones', () async {
      final fake = FakeCrashReporter();
      final reporter = PiiScrubbingCrashReporter(delegate: fake);

      await reporter.captureError(
        StateError('boom'),
        context: const {'email': 'a@b.com', 'screen': 'home'},
      );

      expect(fake.errors.single.context['email'], '[redacted]');
      expect(fake.errors.single.context['screen'], 'home');
    });

    test('redacts emails inside messages', () async {
      final fake = FakeCrashReporter();
      final reporter = PiiScrubbingCrashReporter(delegate: fake);

      await reporter.captureMessage('user jane@x.com failed to sync');

      expect(fake.messages.single, contains('[redacted]'));
      expect(fake.messages.single, isNot(contains('jane@x.com')));
    });

    test('redacts breadcrumb data', () async {
      final fake = FakeCrashReporter();
      final reporter = PiiScrubbingCrashReporter(delegate: fake);

      await reporter.addBreadcrumb('open', data: const {'token': 'secret'});

      expect(fake.breadcrumbs.single.data['token'], '[redacted]');
    });

    test('redacts setContext values', () async {
      final fake = FakeCrashReporter();
      final reporter = PiiScrubbingCrashReporter(delegate: fake);

      await reporter.setContext('app', const {'api_key': 'k', 'env': 'prod'});

      expect(fake.contexts['app']!['api_key'], '[redacted]');
      expect(fake.contexts['app']!['env'], 'prod');
    });

    test('forwards the pseudonymous user id unchanged', () async {
      final fake = FakeCrashReporter();
      final reporter = PiiScrubbingCrashReporter(delegate: fake);

      await reporter.setUser('user-1');

      expect(fake.userId, 'user-1');
    });
  });
}
