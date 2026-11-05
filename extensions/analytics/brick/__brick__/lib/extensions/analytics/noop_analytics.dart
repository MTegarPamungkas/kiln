import 'package:kiln_core/kiln_core.dart';

/// [Analytics] that intentionally does nothing.
///
/// Used when the API key is empty or the current flavor is not allowed to
/// send events, so application code can keep calling analytics safely.
final class NoopAnalytics implements Analytics {
  const NoopAnalytics();

  @override
  Future<void> capture(
    String event, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) => Future<void>.value();

  @override
  Future<void> identify(
    String userId, {
    Map<String, Object?> traits = const <String, Object?>{},
  }) => Future<void>.value();

  @override
  Future<void> reset() => Future<void>.value();
}
