import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/analytics/analytics_config.dart';
import 'package:{{app_name}}/extensions/analytics/analytics_gateway.dart';
import 'package:{{app_name}}/extensions/analytics/analytics_module.dart';
import 'package:{{app_name}}/extensions/analytics/analytics_support.dart';
import 'package:{{app_name}}/extensions/analytics/consent_gate_analytics.dart';
import 'package:{{app_name}}/extensions/analytics/posthog_analytics.dart';
import 'package:{{app_name}}/extensions/analytics/session_identity_listener.dart';

import 'test_support.dart';

Registry _registry({AppFlavor? flavor}) {
  final registry = GetItRegistry()
    ..registerSingleton<ConsentController>(ConsentController())
    ..registerSingleton<SessionController>(SessionController());
  if (flavor != null) {
    registry.registerSingleton<AppFlavor>(flavor);
  }
  return registry;
}

void main() {
  group('AnalyticsModule', () {
    test('late SDK setup is disabled after disposal and cannot send events', () async {
      final registry = _registry();
      registry.read<ConsentController>().grant(ConsentCategory.analytics);
      final gate = Completer<void>();
      final gateway = FakeAnalyticsGateway()..setupGate = gate;
      final module = AnalyticsModule(config: AnalyticsConfig(apiKey: 'phc_test'),
        gatewayFactory: () => gateway);
      module.register(registry);
      final reporter = registry.read<Analytics>();
      final ready = module.ready(registry);
      await Future<void>.delayed(Duration.zero);
      await module.dispose();
      await reporter.capture('after-dispose');
      expect(gateway.events, isEmpty);
      gate.complete();
      await ready;
      expect(gateway.setupConsent, [false]);
      expect(gateway.enabledStates, isNot(contains(true)));
      expect(gateway.shutdownCalls, 2);
      await module.dispose();
      expect(gateway.shutdownCalls, 2);
    });
    test('registers the gated Analytics without raw SDK seams', () async {
      final registry = _registry();
      final gateway = FakeAnalyticsGateway();
      final module = AnalyticsModule(gatewayFactory: () => gateway);

      module.register(registry);

      expect(registry.read<Analytics>(), isA<ConsentGateAnalytics>());
      expect(registry.read<AnalyticsConfig>(), AnalyticsConfig.defaults);
      expect(registry.read<AnalyticsSupport>(), isA<AnalyticsSupport>());
      expect(
        registry.read<SessionIdentityListener>(),
        isA<SessionIdentityListener>(),
      );
      expect(registry.readOrNull<AnalyticsGateway>(), isNull);
      expect(registry.readOrNull<PosthogAnalytics>(), isNull);

      await module.dispose();
    });

    test('waits for consent before initializing the SDK', () async {
      final registry = _registry();
      final gateway = FakeAnalyticsGateway();
      final config = AnalyticsConfig(apiKey: 'phc_test');
      final module = AnalyticsModule(
        config: config,
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);

      expect(gateway.setupCalls, 0);
      var info = await module.support(registry);
      expect(info.state, SupportState.notConfigured);
      expect(info.message, contains('consent'));

      registry.read<ConsentController>().grant(ConsentCategory.analytics);
      await module.idle;

      expect(gateway.setupCalls, 1);
      expect(gateway.setups.single, same(config));
      expect(gateway.setupConsent.single, isTrue);
      info = await module.support(registry);
      expect(info.isSupported, isTrue);

      await module.dispose();
      expect(gateway.shutdownCalls, 1);
    });

    test('identifies the current session after consent is granted', () async {
      final registry = _registry();
      final gateway = FakeAnalyticsGateway();
      final module = AnalyticsModule(
        config: AnalyticsConfig(apiKey: 'phc_test'),
        gatewayFactory: () => gateway,
      );
      registry.read<SessionController>().setSession(
        const AuthSession(userId: 'user-1'),
      );

      module.register(registry);
      await module.ready(registry);
      expect(gateway.identities, isEmpty);

      registry.read<ConsentController>().grant(ConsentCategory.analytics);
      await module.idle;
      await registry.read<SessionIdentityListener>().idle;

      expect(gateway.identities, hasLength(1));
      expect(gateway.lastIdentity?.userId, 'user-1');

      await module.dispose();
    });

    test('disables the SDK on revoke and rotates identity on the next grant',
        () async {
      final registry = _registry();
      final gateway = FakeAnalyticsGateway();
      final module = AnalyticsModule(
        config: AnalyticsConfig(apiKey: 'phc_test'),
        gatewayFactory: () => gateway,
      );
      module.register(registry);
      await module.ready(registry);
      final consent = registry.read<ConsentController>();
      consent.grant(ConsentCategory.analytics);
      await module.idle;
      expect(gateway.setupCalls, 1);
      // Every grant opts in: optOut persists across launches.
      expect(gateway.enabledStates, <bool>[true]);

      consent.deny(ConsentCategory.analytics);
      await module.idle;

      // Reset reloads feature flags, i.e. a request after consent ended, so the
      // identity rotation is deferred to the next grant.
      expect(gateway.enabledStates, <bool>[true, false]);
      expect(gateway.resetCalls, 0);
      expect(
        (await module.support(registry)).state,
        SupportState.notConfigured,
      );

      consent.grant(ConsentCategory.analytics);
      await module.idle;

      expect(gateway.resetCalls, 1);
      expect(gateway.setupCalls, 1);
      expect(gateway.enabledStates, <bool>[true, false, true]);
      expect((await module.support(registry)).isSupported, isTrue);

      await module.dispose();
    });

    test('uses NoopAnalytics when the API key is empty', () async {
      final registry = _registry();
      final gateway = FakeAnalyticsGateway();
      final module = AnalyticsModule(
        config: AnalyticsConfig(apiKey: ''),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);

      registry.read<ConsentController>().grant(ConsentCategory.analytics);
      await module.idle;
      await registry.read<Analytics>().capture('project created');

      expect(gateway.setupCalls, 0);
      expect(gateway.events, isEmpty);
      expect(registry.read<SessionIdentityListener>().isRunning, isTrue);

      await module.dispose();
    });

    test('uses NoopAnalytics when the flavor is not enabled', () async {
      final registry = _registry(flavor: AppFlavor.development);
      final gateway = FakeAnalyticsGateway();
      final module = AnalyticsModule(
        config: AnalyticsConfig(
          apiKey: 'phc_test',
          enabledFlavors: <AppFlavor>{AppFlavor.production},
        ),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);

      registry.read<ConsentController>().grant(ConsentCategory.analytics);
      await module.idle;
      await registry.read<Analytics>().capture('project created');

      expect(gateway.setupCalls, 0);
      expect(gateway.events, isEmpty);

      await module.dispose();
    });

    test('re-records support so bootstrap snapshot follows consent', () async {
      final support = SupportRegistry();
      final registry = _registry()
        ..registerSingleton<SupportRegistry>(support);
      final gateway = FakeAnalyticsGateway();
      final module = AnalyticsModule(
        config: AnalyticsConfig(apiKey: 'phc_test'),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      support.record('analytics', await module.support(registry));
      expect(support['analytics']?.state, SupportState.notConfigured);

      registry.read<ConsentController>().grant(ConsentCategory.analytics);
      await module.idle;

      expect(support['analytics']?.isSupported, isTrue);
      expect(gateway.setupCalls, 1);

      registry.read<ConsentController>().deny(ConsentCategory.analytics);
      await module.idle;

      expect(support['analytics']?.isSupported, isFalse);
      expect(gateway.setupCalls, 1);

      await module.dispose();
    });

    test('keeps starting when PostHog setup fails and retries later', () async {
      final registry = _registry();
      final gateway = FakeAnalyticsGateway()
        ..failure = StateError('posthog unavailable');
      final module = AnalyticsModule(
        config: AnalyticsConfig(apiKey: 'phc_test'),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);
      final consent = registry.read<ConsentController>();
      final listener = registry.read<SessionIdentityListener>();
      consent.grant(ConsentCategory.analytics);
      await module.idle;

      expect(gateway.setupCalls, 1);
      expect(listener.isRunning, isTrue);

      gateway.failure = null;
      consent.deny(ConsentCategory.analytics);
      await module.idle;
      consent.grant(ConsentCategory.analytics);
      await module.idle;

      expect(gateway.setupCalls, 2);

      registry.read<SessionController>().setSession(
        const AuthSession(userId: 'user-1'),
      );
      await listener.idle;
      expect(gateway.identities, hasLength(1));

      await module.dispose();
    });
  });
}
