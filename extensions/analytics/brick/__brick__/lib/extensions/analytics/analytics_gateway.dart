import 'analytics_config.dart';

/// Analytics access that can be replaced with a fake in tests.
abstract interface class AnalyticsGateway {
  /// Prepares the SDK for [config].
  Future<void> setup(AnalyticsConfig config);

  /// Sends one event with JSON-like [properties].
  Future<void> capture(String event, Map<String, Object?> properties);

  /// Associates later events with [userId] and stores [traits].
  Future<void> identify(String userId, Map<String, Object?> traits);

  /// Clears the currently identified user.
  Future<void> reset();

  /// Sends queued events as soon as possible.
  Future<void> flush();
}
