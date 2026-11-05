import 'package:posthog_flutter/posthog_flutter.dart';

import 'analytics_config.dart';
import 'analytics_gateway.dart';

/// [AnalyticsGateway] backed by the `posthog_flutter` plugin.
///
/// Tests replace this class with a fake so no platform channel is touched.
final class SdkPosthogGateway implements AnalyticsGateway {
  SdkPosthogGateway();

  Posthog get _posthog => Posthog();

  @override
  Future<void> setup(AnalyticsConfig config) async {
    config.validate();
    final sdkConfig = PostHogConfig(config.apiKey)
      ..host = config.host
      ..flushInterval = config.flushInterval
      // Consent gates capture and identify; automatic lifecycle events would
      // bypass that gate, so they stay off.
      ..captureApplicationLifecycleEvents = false;
    await _posthog.setup(sdkConfig);
  }

  @override
  Future<void> capture(String event, Map<String, Object?> properties) {
    return _posthog.capture(
      eventName: event,
      properties: _sdkProperties(properties),
    );
  }

  @override
  Future<void> identify(String userId, Map<String, Object?> traits) {
    return _posthog.identify(
      userId: userId,
      userProperties: _sdkProperties(traits),
    );
  }

  @override
  Future<void> reset() => _posthog.reset();

  @override
  Future<void> flush() => _posthog.flush();

  Map<String, Object> _sdkProperties(Map<String, Object?> values) {
    return <String, Object>{
      for (final entry in values.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }
}
