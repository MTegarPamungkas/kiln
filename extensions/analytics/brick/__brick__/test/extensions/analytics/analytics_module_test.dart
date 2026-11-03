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
    test('registers Analytics, its config, gateway, and listener', () async {
      final registry = _registry();
      final gateway = FakeAnalyticsGateway();
      final module = AnalyticsModule(gatewayFactory: () => gateway);

      module.register(registry);

      expect(registry.read<Analytics>(), isA<ConsentGateAnalytics>());
      expect(registry.read<AnalyticsConfig>(), AnalyticsConfig.defaults);
      expect(registry.read<AnalyticsSupport>(), isA<AnalyticsSupport>());
      expect(registry.read<AnalyticsGateway>(), same(gateway));
      expect(registry.read<PosthogAnalytics>(), isA<PosthogAnalytics>());
      expect(
        registry.read<SessionIdentityListener>(),
        isA<SessionIdentityListener>(),
      );

      await module.dispose();
    });

    test('sets up the gateway and starts identity sync when active', () async {
      final registry = _registry();
      final gateway = FakeAnalyticsGateway();
      final config = AnalyticsConfig(apiKey: 'phc_test');
      final module = AnalyticsModule(
        config: config,
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);

      expect(gateway.setupCalls, 1);
      expect(gateway.setups.single, same(config));

      final consent = registry.read<ConsentController>();
      consent.grant(ConsentCategory.analytics);
      registry.read<SessionController>().setSession(
        const AuthSession(userId: 'user-1'),
      );
      final listener = registry.read<SessionIdentityListener>();
      await listener.idle;

      expect(listener.isRunning, isTrue);
      expect(gateway.identities, hasLength(1));
      expect(gateway.lastIdentity?.userId, 'user-1');

      await module.dispose();
      expect(listener.isRunning, isFalse);
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
      await registry.read<Analytics>().capture('project created');

      expect(gateway.setupCalls, 0);
      expect(gateway.events, isEmpty);

      await module.dispose();
    });

    test('keeps starting when PostHog setup fails', () async {
      final registry = _registry();
      final gateway = FakeAnalyticsGateway()
        ..failure = StateError('posthog unavailable');
      final module = AnalyticsModule(
        config: AnalyticsConfig(apiKey: 'phc_test'),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);

      expect(gateway.setupCalls, 1);
      final listener = registry.read<SessionIdentityListener>();
      expect(listener.isRunning, isTrue);

      gateway.failure = null;
      registry.read<ConsentController>().grant(ConsentCategory.analytics);
      registry.read<SessionController>().setSession(
        const AuthSession(userId: 'user-1'),
      );
      await listener.idle;
      expect(gateway.identities, hasLength(1));

      await module.dispose();
    });
  });
}
