import 'analytics_config.dart';

/// Analytics access that can be replaced with a fake in tests.
abstract interface class AnalyticsGateway {
  /// Prepares the SDK for [config].
  ///
  /// [isAllowed] reports current consent so the SDK can drop events at the
  /// transport boundary if consent is revoked after setup.
  Future<void> setup(
    AnalyticsConfig config, {
    required bool Function() isAllowed,
  });

  /// Enables or disables sending after a consent change.
  Future<void> setEnabled(bool enabled);

  /// Sends one event with JSON-like [properties].
  Future<void> capture(String event, Map<String, Object?> properties);

  /// Associates later events with [userId] and stores [traits].
  Future<void> identify(String userId, Map<String, Object?> traits);

  /// Clears the currently identified user.
  Future<void> reset();

  /// Sends queued events as soon as possible.
  Future<void> flush();

  /// Flushes queued consent-approved events before the app shuts down.
  Future<void> shutdown();
}
