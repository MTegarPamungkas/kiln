import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/crash_report/crash_report_config.dart';
import 'package:{{app_name}}/extensions/crash_report/crash_report_gateway.dart';
import 'package:{{app_name}}/extensions/crash_report/crash_report_module.dart';
import 'package:{{app_name}}/extensions/crash_report/crash_report_support.dart';
import 'package:{{app_name}}/extensions/crash_report/safe_crash_reporter.dart';
import 'package:{{app_name}}/extensions/crash_report/sentry_crash_reporter.dart';

import 'test_support.dart';

Registry _registry({AppFlavor? flavor}) {
  final registry = GetItRegistry()
    ..registerSingleton<ConsentController>(ConsentController());
  if (flavor != null) {
    registry.registerSingleton<AppFlavor>(flavor);
  }
  return registry;
}

void main() {
  group('CrashReportModule', () {
    test('registers the layered CrashReporter and its parts', () async {
      final registry = _registry();
      final gateway = FakeCrashReportGateway();
      final module = CrashReportModule(gatewayFactory: () => gateway);

      module.register(registry);

      expect(registry.read<CrashReporter>(), isA<SafeCrashReporter>());
      expect(registry.read<CrashReportConfig>(), CrashReportConfig.defaults);
      expect(registry.read<CrashReportSupport>(), isA<CrashReportSupport>());
      expect(registry.read<CrashReportGateway>(), same(gateway));
      expect(registry.read<SentryCrashReporter>(), isA<SentryCrashReporter>());

      await module.dispose();
    });

    test('initializes the gateway once when active', () async {
      final registry = _registry(flavor: AppFlavor.production);
      final gateway = FakeCrashReportGateway();
      final config = CrashReportConfig(dsn: 'https://key@sentry.example.com/1');
      final module = CrashReportModule(
        config: config,
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);

      expect(gateway.initCalls, 1);
      expect(gateway.inits.single, same(config));
      expect(gateway.environments.single, 'production');

      await module.dispose();
    });

    test('reports nothing and skips init when the DSN is empty', () async {
      final registry = _registry();
      final gateway = FakeCrashReportGateway();
      final module = CrashReportModule(
        config: CrashReportConfig(dsn: ''),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);
      registry.read<ConsentController>().grant(ConsentCategory.crashReports);
      await registry.read<CrashReporter>().captureMessage('after consent');

      expect(gateway.initCalls, 0);
      expect(gateway.messages, isEmpty);

      await module.dispose();
    });

    test('keeps starting when Sentry fails to initialize', () async {
      final registry = _registry();
      final gateway = FakeCrashReportGateway()
        ..failure = StateError('sentry down');
      final module = CrashReportModule(
        config: CrashReportConfig(dsn: 'https://key@sentry.example.com/1'),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);

      expect(gateway.initCalls, 1);
      expect(module.support(registry), isNotNull);

      await module.dispose();
    });

    test('routes consent and redaction through the registered reporter', () async {
      final registry = _registry();
      final gateway = FakeCrashReportGateway();
      final module = CrashReportModule(
        config: CrashReportConfig(dsn: 'https://key@sentry.example.com/1'),
        gatewayFactory: () => gateway,
      );
      module.register(registry);

      final reporter = registry.read<CrashReporter>();
      await reporter.captureError(
        StateError('boom'),
        context: const {'email': 'a@b.com'},
      );
      expect(gateway.errors, isEmpty);

      registry.read<ConsentController>().grant(ConsentCategory.crashReports);
      await reporter.captureError(
        StateError('boom'),
        context: const {'email': 'a@b.com'},
      );

      expect(gateway.errors, hasLength(1));
      expect(gateway.lastError?.context['email'], '[redacted]');

      await module.dispose();
    });
  });
}
