import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/crash_report/consent_gate_crash_reporter.dart';

void main() {
  group('ConsentGateCrashReporter', () {
    test('drops reports before crash-report consent is granted', () async {
      final fake = FakeCrashReporter();
      final reporter = ConsentGateCrashReporter(
        delegate: fake,
        consent: ConsentController(),
      );

      await reporter.captureError(StateError('boom'));
      await reporter.captureMessage('later');
      await reporter.addBreadcrumb('open');
      await reporter.setContext('app', const {'a': 1});

      expect(fake.errors, isEmpty);
      expect(fake.messages, isEmpty);
      expect(fake.breadcrumbs, isEmpty);
      expect(fake.contexts, isEmpty);
    });

    test('does not accept other consent categories', () async {
      final fake = FakeCrashReporter();
      final reporter = ConsentGateCrashReporter(
        delegate: fake,
        consent: ConsentController(analytics: true),
      );

      await reporter.captureMessage('nope');

      expect(fake.messages, isEmpty);
    });

    test('starts reporting once consent is granted', () async {
      final fake = FakeCrashReporter();
      final consent = ConsentController();
      final reporter = ConsentGateCrashReporter(
        delegate: fake,
        consent: consent,
      );

      await reporter.captureMessage('before');
      consent.grant(ConsentCategory.crashReports);
      await reporter.captureMessage('after');

      expect(fake.messages, <String>['after']);
    });

    test('stops reporting once consent is withdrawn', () async {
      final fake = FakeCrashReporter();
      final consent = ConsentController(crashReports: true);
      final reporter = ConsentGateCrashReporter(
        delegate: fake,
        consent: consent,
      );

      await reporter.captureMessage('first');
      consent.deny(ConsentCategory.crashReports);
      await reporter.captureMessage('second');

      expect(fake.messages, <String>['first']);
    });

    test('withholds a non-null user id before consent', () async {
      final fake = FakeCrashReporter();
      final reporter = ConsentGateCrashReporter(
        delegate: fake,
        consent: ConsentController(),
      );

      await reporter.setUser('user-1');

      expect(fake.userId, isNull);
    });

    test('always forwards setUser(null) so sign-out clears identity', () async {
      final fake = FakeCrashReporter();
      final consent = ConsentController();
      final reporter = ConsentGateCrashReporter(
        delegate: fake,
        consent: consent,
      );

      consent.grant(ConsentCategory.crashReports);
      await reporter.setUser('user-1');
      consent.deny(ConsentCategory.crashReports);
      await reporter.setUser(null);

      expect(fake.userId, isNull);
    });
  });
}
