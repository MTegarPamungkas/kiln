/// Reports crashes, messages, breadcrumbs, and user context to a vendor.
abstract interface class CrashReporter {
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  });

  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  });

  Future<void> addBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  });

  Future<void> setUser(String? userId);

  Future<void> setContext(String key, Map<String, Object?> value);
}
