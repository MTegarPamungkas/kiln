// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';

/// [Analytics] that drops every event until analytics consent is granted.
///
/// Consent is checked on each call, so granting it later starts sending
/// without rebuilding the module. [reset] is always forwarded because it
/// clears locally stored identity and never sends an event.
final class ConsentGateAnalytics implements Analytics {
  const ConsentGateAnalytics({
    required Analytics delegate,
    required ConsentController consent,
  }) : _delegate = delegate,
       _consent = consent;

  final Analytics _delegate;
  final ConsentController _consent;

  bool get isAllowed => _consent.isGranted(ConsentCategory.analytics);

  @override
  Future<void> capture(
    String event, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) {
    if (!isAllowed) {
      return Future<void>.value();
    }
    return _delegate.capture(event, properties: properties);
  }

  @override
  Future<void> identify(
    String userId, {
    Map<String, Object?> traits = const <String, Object?>{},
  }) {
    if (!isAllowed) {
      return Future<void>.value();
    }
    return _delegate.identify(userId, traits: traits);
  }

  @override
  Future<void> reset() => _delegate.reset();
}
