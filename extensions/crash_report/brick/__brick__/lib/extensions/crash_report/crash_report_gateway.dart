import 'crash_report_config.dart';

/// Crash reporting access that can be replaced with a fake in tests.
///
/// The interface mirrors the vendor-neutral `CrashReporter` contract plus the
/// lifecycle calls (`init`, `flush`, `close`) that only the SDK gateway needs.
abstract interface class CrashReportGateway {
  /// Prepares the vendor SDK for [config], using [environment] when given.
  Future<void> init(CrashReportConfig config, {String? environment});

  /// Reports [error] with an optional [stackTrace] and structured [context].
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  });

  /// Reports a standalone [message].
  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  });

  /// Records a breadcrumb that travels with later events.
  Future<void> addBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  });

  /// Attaches the current user id, or clears it when [userId] is null.
  Future<void> setUser(String? userId);

  /// Stores keyed [value] context for later events.
  Future<void> setContext(String key, Map<String, Object?> value);

  /// Sends queued events as soon as possible.
  Future<void> flush();

  /// Flushes and shuts the vendor SDK down.
  Future<void> close();
}
