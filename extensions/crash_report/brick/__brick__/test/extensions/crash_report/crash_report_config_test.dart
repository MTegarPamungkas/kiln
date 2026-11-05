import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/crash_report/crash_report_config.dart';

void main() {
  group('CrashReportConfig', () {
    test('an empty DSN makes the reporter a noop', () {
      final config = CrashReportConfig(dsn: '');

      expect(config.isNoop, isTrue);
      expect(config.isActiveFor(AppFlavor.production), isFalse);
    });

    test('a DSN sends for an enabled flavor', () {
      final config = CrashReportConfig(dsn: 'https://key@sentry.example.com/1');

      expect(config.isNoop, isFalse);
      expect(config.isActiveFor(AppFlavor.production), isTrue);
    });

    test('a flavor outside the enabled set does not send', () {
      final config = CrashReportConfig(
        dsn: 'https://key@sentry.example.com/1',
        enabledFlavors: <AppFlavor>{AppFlavor.staging},
      );

      expect(config.isActiveFor(AppFlavor.production), isFalse);
    });

    test('validate rejects a non-absolute DSN', () {
      expect(
        () => CrashReportConfig(dsn: 'not-a-url').validate(),
        throwsA(isA<Failure>()),
      );
    });

    test('validate rejects a sample rate outside 0..1', () {
      expect(
        () => CrashReportConfig(
          dsn: 'https://key@sentry.example.com/1',
          sampleRate: 1.5,
        ).validate(),
        throwsA(isA<Failure>()),
      );
    });

    test('environmentFor prefers the override, then the flavor', () {
      expect(
        CrashReportConfig().environmentFor(AppFlavor.development),
        'development',
      );
      expect(
        CrashReportConfig(environment: 'eu-prod').environmentFor(
          AppFlavor.production,
        ),
        'eu-prod',
      );
    });

    test('toString masks the DSN', () {
      final text = CrashReportConfig(dsn: 'https://secret-key@sentry/1')
          .toString();

      expect(text, isNot(contains('secret-key')));
      expect(text, contains('[set]'));
    });
  });
}
