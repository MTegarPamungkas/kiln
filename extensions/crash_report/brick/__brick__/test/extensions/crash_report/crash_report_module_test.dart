import 'dart:async';

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
    test('late SDK initialization is closed again after disposal', () async {
      final registry = _registry();
      registry.read<ConsentController>().grant(ConsentCategory.crashReports);
      final gate = Completer<void>();
      final gateway = FakeCrashReportGateway()..initGate = gate;
      final module = CrashReportModule(
        config: CrashReportConfig(dsn: 'https://public@example.test/1'),
        gatewayFactory: () => gateway);
      module.register(registry);
      final reporter = registry.read<CrashReporter>();
      final ready = module.ready(registry);
      await Future<void>.delayed(Duration.zero);
      await module.dispose();
      await reporter.captureMessage('after-dispose');
      expect(gateway.messages, isEmpty);
      gate.complete();
      await ready;
      expect(gateway.initConsent, [false]);
      expect(gateway.closeCalls, 2);
      await module.dispose();
      expect(gateway.closeCalls, 2);
    });
    test('registers the gated reporter without raw SDK seams', () async {
      final registry = _registry();
      final gateway = FakeCrashReportGateway();
      final module = CrashReportModule(gatewayFactory: () => gateway);

      module.register(registry);

      expect(registry.read<CrashReporter>(), isA<SafeCrashReporter>());
      expect(registry.read<CrashReportConfig>(), CrashReportConfig.defaults);
      expect(registry.read<CrashReportSupport>(), isA<CrashReportSupport>());
      expect(registry.readOrNull<CrashReportGateway>(), isNull);
      expect(registry.readOrNull<SentryCrashReporter>(), isNull);

      await module.dispose();
    });

    test('waits for consent before initializing Sentry', () async {
      final registry = _registry(flavor: AppFlavor.production);
      final gateway = FakeCrashReportGateway();
      final config = CrashReportConfig(dsn: 'https://key@sentry.example.com/1');
      final module = CrashReportModule(
        config: config,
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);

      expect(gateway.initCalls, 0);
      var info = await module.support(registry);
      expect(info.state, SupportState.notConfigured);
      expect(info.message, contains('consent'));

      registry.read<ConsentController>().grant(ConsentCategory.crashReports);
      await module.idle;

      expect(gateway.initCalls, 1);
      expect(gateway.inits.single, same(config));
      expect(gateway.environments.single, 'production');
      expect(gateway.initConsent.single, isTrue);
      info = await module.support(registry);
      expect(info.isSupported, isTrue);

      await module.dispose();
    });

    test('clears the user identity when consent is revoked', () async {
      final registry = _registry();
      final gateway = FakeCrashReportGateway();
      final module = CrashReportModule(
        config: CrashReportConfig(dsn: 'https://key@sentry.example.com/1'),
        gatewayFactory: () => gateway,
      );
      module.register(registry);
      await module.ready(registry);
      final consent = registry.read<ConsentController>();
      consent.grant(ConsentCategory.crashReports);
      await module.idle;

      await registry.read<CrashReporter>().setUser('user-1');
      expect(gateway.userId, 'user-1');

      consent.deny(ConsentCategory.crashReports);
      await module.idle;

      expect(gateway.userId, isNull);
      expect(gateway.initCalls, 1);
      expect(
        (await module.support(registry)).state,
        SupportState.notConfigured,
      );

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
      await module.idle;
      await registry.read<CrashReporter>().captureMessage('after consent');

      expect(gateway.initCalls, 0);
      expect(gateway.messages, isEmpty);

      await module.dispose();
    });

    test('keeps starting when Sentry fails to initialize and retries later', () async {
      final registry = _registry();
      final gateway = FakeCrashReportGateway()
        ..failure = StateError('sentry down');
      final module = CrashReportModule(
        config: CrashReportConfig(dsn: 'https://key@sentry.example.com/1'),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);
      final consent = registry.read<ConsentController>();
      consent.grant(ConsentCategory.crashReports);
      await module.idle;

      expect(gateway.initCalls, 1);

      gateway.failure = null;
      consent.deny(ConsentCategory.crashReports);
      await module.idle;
      consent.grant(ConsentCategory.crashReports);
      await module.idle;

      expect(gateway.initCalls, 2);

      await module.dispose();
    });

    test('re-records support so bootstrap snapshot follows consent', () async {
      final support = SupportRegistry();
      final registry = _registry()
        ..registerSingleton<SupportRegistry>(support);
      final gateway = FakeCrashReportGateway();
      final module = CrashReportModule(
        config: CrashReportConfig(dsn: 'https://public@example.com/1'),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      support.record('crash_report', await module.support(registry));
      expect(support['crash_report']?.state, SupportState.notConfigured);

      registry.read<ConsentController>().grant(ConsentCategory.crashReports);
      await module.idle;

      expect(support['crash_report']?.isSupported, isTrue);
      expect(gateway.initCalls, 1);

      registry.read<ConsentController>().deny(ConsentCategory.crashReports);
      await module.idle;

      expect(support['crash_report']?.isSupported, isFalse);
      expect(gateway.initCalls, 1);

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
