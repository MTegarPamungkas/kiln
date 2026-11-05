import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/crash_report/crash_report_config.dart';
import 'package:{{app_name}}/extensions/crash_report/crash_report_support.dart';

void main() {
  group('CrashReportSupport', () {
    test('is not configured when the DSN is empty', () async {
      final support = CrashReportSupport(
        config: CrashReportConfig(dsn: ''),
        flavor: null,
        probe: () async {},
      );

      final info = await support.check();

      expect(info.state, SupportState.notConfigured);
      expect(info.isSupported, isFalse);
    });

    test('is supported when active and the probe succeeds', () async {
      final support = CrashReportSupport(
        config: CrashReportConfig(dsn: 'https://key@sentry.example.com/1'),
        flavor: AppFlavor.production,
        probe: () async {},
      );

      final info = await support.check();

      expect(info.isSupported, isTrue);
    });

    test('is unavailable when the probe fails', () async {
      final support = CrashReportSupport(
        config: CrashReportConfig(dsn: 'https://key@sentry.example.com/1'),
        flavor: AppFlavor.production,
        probe: () async => throw StateError('sentry down'),
      );

      final info = await support.check();

      expect(info.state, SupportState.unavailable);
    });

    test('caches the probe result', () async {
      var calls = 0;
      final support = CrashReportSupport(
        config: CrashReportConfig(dsn: 'https://key@sentry.example.com/1'),
        flavor: AppFlavor.production,
        probe: () async {
          calls++;
        },
      );

      await support.check();
      await support.check();

      expect(calls, 1);
    });
  });
}
