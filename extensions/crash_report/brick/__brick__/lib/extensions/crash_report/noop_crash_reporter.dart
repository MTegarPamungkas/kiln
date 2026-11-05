import 'package:kiln_core/kiln_core.dart';

/// [CrashReporter] that intentionally does nothing.
///
/// Used when the DSN is empty or the current flavor may not send reports, so
/// application code can keep calling the reporter safely.
final class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) => Future<void>.value();

  @override
  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) => Future<void>.value();

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  }) => Future<void>.value();

  @override
  Future<void> setUser(String? userId) => Future<void>.value();

  @override
  Future<void> setContext(
    String key,
    Map<String, Object?> value,
  ) => Future<void>.value();
}
