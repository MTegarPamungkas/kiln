// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';

/// [Analytics] decorator that removes personal data before it leaves the app.
///
/// Event properties and identity traits are passed through [PiiRedactor].
/// User ids are left untouched because they are pseudonymous identifiers used
/// to join events, not profile data.
final class PiiScrubbingAnalytics implements Analytics {
  const PiiScrubbingAnalytics({
    required Analytics delegate,
    PiiRedactor redactor = const PiiRedactor(),
  }) : _delegate = delegate,
       _redactor = redactor;

  final Analytics _delegate;
  final PiiRedactor _redactor;

  @override
  Future<void> capture(
    String event, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) {
    return _delegate.capture(event, properties: _redactor.redactMap(properties));
  }

  @override
  Future<void> identify(
    String userId, {
    Map<String, Object?> traits = const <String, Object?>{},
  }) {
    return _delegate.identify(userId, traits: _redactor.redactMap(traits));
  }

  @override
  Future<void> reset() => _delegate.reset();
}
