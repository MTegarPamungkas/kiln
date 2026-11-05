import 'package:kiln_core/kiln_core.dart';

/// Gate verbs for the crash reporting capability.
///
/// `kiln_core` already exposes [Gate.reportError] and [Gate.reportMessage];
/// this extension adds the remaining `CrashReporter` verbs as single calls that
/// return a [Result], plus a consent probe. The application owns the UI.
extension GateCrashReportX on Gate {
  /// Whether crash reporting is currently allowed by consent.
  bool get crashReportsConsented =>
      consent.isGranted(ConsentCategory.crashReports);

  /// Records a breadcrumb that travels with later reports.
  Future<Result<void>> reportBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  }) => call<void>(() => crashReporter.addBreadcrumb(message, data: data));

  /// Attaches the current user id, or clears it when [userId] is null.
  Future<Result<void>> setReportUser(String? userId) =>
      call<void>(() => crashReporter.setUser(userId));

  /// Stores keyed [value] context for later reports.
  Future<Result<void>> setReportContext(
    String key,
    Map<String, Object?> value,
  ) => call<void>(() => crashReporter.setContext(key, value));
}
