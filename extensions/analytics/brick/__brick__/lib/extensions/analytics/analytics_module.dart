import 'package:kiln_core/kiln_core.dart';

import 'analytics_config.dart';
import 'analytics_gateway.dart';
import 'consent_gate_analytics.dart';
import 'noop_analytics.dart';
import 'pii_scrubbing_analytics.dart';
import 'posthog_analytics.dart';
import 'sdk_posthog_gateway.dart';
import 'session_identity_listener.dart';

/// Registers [Analytics] on top of PostHog.
///
/// The decorator order is [ConsentGateAnalytics] outermost, then
/// [PiiScrubbingAnalytics], then either [PosthogAnalytics] or
/// [NoopAnalytics]. Nothing reaches the SDK, and no property is scrubbed,
/// before analytics consent is granted.
final class AnalyticsModule extends KilnModule {
  AnalyticsModule({
    AnalyticsConfig? config,
    AnalyticsGateway Function()? gatewayFactory,
  }) : _config = config ?? AnalyticsConfig.defaults,
       _gatewayFactory = gatewayFactory ?? SdkPosthogGateway.new;

  final AnalyticsConfig _config;
  final AnalyticsGateway Function() _gatewayFactory;
  AnalyticsGateway? _gateway;
  SessionIdentityListener? _listener;

  @override
  String get id => 'analytics';

  @override
  Set<String> get provides => const <String>{'analytics'};

  @override
  Set<String> get optionalRequires => const <String>{'flavor'};

  @override
  void register(Registry registry) {
    final gateway = _gatewayFactory();
    _gateway = gateway;
    final posthog = PosthogAnalytics(gateway: gateway);
    final flavor = registry.readOrNull<AppFlavor>();
    final sends = _config.isActiveFor(flavor);

    final Analytics base = sends ? posthog : const NoopAnalytics();
    final scrubbed = PiiScrubbingAnalytics(delegate: base);
    final analytics = ConsentGateAnalytics(
      delegate: scrubbed,
      consent: registry.read<ConsentController>(),
    );
    final listener = SessionIdentityListener(
      sessions: registry.read<SessionController>(),
      analytics: analytics,
    );
    _listener = listener;

    registry
      ..registerSingleton<AnalyticsConfig>(_config)
      ..registerSingleton<AnalyticsGateway>(gateway)
      ..registerSingleton<PosthogAnalytics>(posthog)
      ..registerSingleton<Analytics>(analytics)
      ..registerSingleton<SessionIdentityListener>(listener);
  }

  @override
  Future<void> ready(Registry registry) async {
    final flavor = registry.readOrNull<AppFlavor>();
    if (_config.isActiveFor(flavor)) {
      try {
        await _gateway?.setup(_config);
      } on Object {
        // PostHog may be unreachable or unsupported; the app still starts.
      }
    }
    _listener?.start();
  }

  @override
  Future<void> dispose() async {
    final listener = _listener;
    _listener = null;
    await listener?.dispose();
  }
}
