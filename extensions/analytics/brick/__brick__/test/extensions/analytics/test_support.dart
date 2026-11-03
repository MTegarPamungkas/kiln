import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/analytics/analytics_config.dart';
import 'package:{{app_name}}/extensions/analytics/analytics_gateway.dart';
import 'package:{{app_name}}/extensions/analytics/posthog_analytics.dart';

/// One event received by [FakeAnalyticsGateway].
final class RecordedAnalyticsEvent {
  const RecordedAnalyticsEvent(this.name, this.properties);

  final String name;
  final Map<String, Object?> properties;
}

/// One identity received by [FakeAnalyticsGateway].
final class RecordedAnalyticsIdentity {
  const RecordedAnalyticsIdentity(this.userId, this.traits);

  final String userId;
  final Map<String, Object?> traits;
}

/// [AnalyticsGateway] that records calls instead of touching the SDK.
final class FakeAnalyticsGateway implements AnalyticsGateway {
  final List<RecordedAnalyticsEvent> events = <RecordedAnalyticsEvent>[];
  final List<RecordedAnalyticsIdentity> identities =
      <RecordedAnalyticsIdentity>[];
  final List<AnalyticsConfig> setups = <AnalyticsConfig>[];
  int setupCalls = 0;
  int resetCalls = 0;
  int flushCalls = 0;
  Object? failure;

  RecordedAnalyticsEvent? get lastEvent => events.isEmpty ? null : events.last;

  RecordedAnalyticsIdentity? get lastIdentity =>
      identities.isEmpty ? null : identities.last;

  @override
  Future<void> setup(AnalyticsConfig config) async {
    setupCalls++;
    _maybeFail();
    setups.add(config);
  }

  @override
  Future<void> capture(String event, Map<String, Object?> properties) async {
    _maybeFail();
    events.add(RecordedAnalyticsEvent(event, properties));
  }

  @override
  Future<void> identify(String userId, Map<String, Object?> traits) async {
    _maybeFail();
    identities.add(RecordedAnalyticsIdentity(userId, traits));
  }

  @override
  Future<void> reset() async {
    _maybeFail();
    resetCalls++;
  }

  @override
  Future<void> flush() async {
    _maybeFail();
    flushCalls++;
  }

  void _maybeFail() {
    final error = failure;
    if (error != null) {
      throw error;
    }
  }
}

/// Contract harness backed by [FakeAnalyticsGateway].
final class FakeGatewayAnalyticsHarness implements AnalyticsContractHarness {
  FakeGatewayAnalyticsHarness([FakeAnalyticsGateway? gateway])
    : gateway = gateway ?? FakeAnalyticsGateway() {
    analytics = PosthogAnalytics(gateway: this.gateway);
  }

  final FakeAnalyticsGateway gateway;

  @override
  late final Analytics analytics;

  @override
  int get eventCount => gateway.events.length;

  @override
  String? get lastEventName => gateway.lastEvent?.name;

  @override
  Map<String, Object?> get lastEventProperties =>
      gateway.lastEvent?.properties ?? const <String, Object?>{};

  @override
  int get identifyCount => gateway.identities.length;

  @override
  String? get lastUserId => gateway.lastIdentity?.userId;

  @override
  Map<String, Object?> get lastTraits =>
      gateway.lastIdentity?.traits ?? const <String, Object?>{};

  @override
  int get resetCount => gateway.resetCalls;
}
