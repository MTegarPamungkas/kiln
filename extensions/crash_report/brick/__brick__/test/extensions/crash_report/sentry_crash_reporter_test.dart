import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/crash_report/sentry_crash_reporter.dart';

import 'test_support.dart';

void main() {
  group('SentryCrashReporter', () {
    test('captureError forwards the error, stack, and context', () async {
      final gateway = FakeCrashReportGateway();
      final reporter = SentryCrashReporter(gateway: gateway);
      final error = StateError('boom');

      await reporter.captureError(error, context: const {'screen': 'home'});

      expect(gateway.errors, hasLength(1));
      expect(gateway.lastError?.error, same(error));
      expect(gateway.lastError?.context['screen'], 'home');
    });

    test('captureMessage forwards the message', () async {
      final gateway = FakeCrashReportGateway();
      final reporter = SentryCrashReporter(gateway: gateway);

      await reporter.captureMessage('Checkout failed');

      expect(gateway.lastMessage?.message, 'Checkout failed');
    });

    test('empty message is rejected before reaching the gateway', () async {
      final gateway = FakeCrashReportGateway();
      final reporter = SentryCrashReporter(gateway: gateway);

      expect(
        () => reporter.captureMessage('   '),
        throwsA(isA<Failure>()),
      );
      expect(gateway.messages, isEmpty);
    });

    test('empty breadcrumb is rejected', () async {
      final reporter = SentryCrashReporter(gateway: FakeCrashReportGateway());

      expect(
        () => reporter.addBreadcrumb(''),
        throwsA(isA<Failure>()),
      );
    });

    test('gateway failures map to a Failure', () async {
      final gateway = FakeCrashReportGateway()
        ..failure = StateError('sentry offline');
      final reporter = SentryCrashReporter(gateway: gateway);

      await expectLater(
        reporter.captureError(StateError('x')),
        throwsA(isA<Failure>()),
      );
    });

    test('flush and close forward to the gateway', () async {
      final gateway = FakeCrashReportGateway();
      final reporter = SentryCrashReporter(gateway: gateway);

      await reporter.flush();
      await reporter.close();

      expect(gateway.flushCalls, 1);
      expect(gateway.closeCalls, 1);
    });
  });
}
