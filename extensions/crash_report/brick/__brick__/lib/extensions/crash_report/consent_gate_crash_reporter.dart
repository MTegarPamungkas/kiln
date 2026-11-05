// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';

/// [CrashReporter] that reports nothing until crash-report consent is granted.
///
/// Consent is checked on every call, so granting it later starts reporting
/// without rebuilding the module. [setUser] with a null id is always forwarded
/// so a sign-out clears the Sentry user even before consent exists; attaching a
/// non-null identity is withheld until consent.
final class ConsentGateCrashReporter implements CrashReporter {
  const ConsentGateCrashReporter({
    required CrashReporter delegate,
    required ConsentController consent,
  }) : _delegate = delegate,
       _consent = consent;

  final CrashReporter _delegate;
  final ConsentController _consent;

  bool get isAllowed => _consent.isGranted(ConsentCategory.crashReports);

  @override
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    if (!isAllowed) {
      return Future<void>.value();
    }
    return _delegate.captureError(
      error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  @override
  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    if (!isAllowed) {
      return Future<void>.value();
    }
    return _delegate.captureMessage(message, context: context);
  }

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    if (!isAllowed) {
      return Future<void>.value();
    }
    return _delegate.addBreadcrumb(message, data: data);
  }

  @override
  Future<void> setUser(String? userId) {
    if (!isAllowed && userId != null) {
      return Future<void>.value();
    }
    return _delegate.setUser(userId);
  }

  @override
  Future<void> setContext(String key, Map<String, Object?> value) {
    if (!isAllowed) {
      return Future<void>.value();
    }
    return _delegate.setContext(key, value);
  }
}
