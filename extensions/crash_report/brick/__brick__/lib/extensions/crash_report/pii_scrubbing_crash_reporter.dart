// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';

/// [CrashReporter] decorator that removes personal data before it leaves the app.
///
/// Error context, message text, breadcrumb data, and context maps all pass
/// through [PiiRedactor]. User ids are forwarded untouched because they are
/// pseudonymous identifiers used to group reports, not profile data.
final class PiiScrubbingCrashReporter implements CrashReporter {
  const PiiScrubbingCrashReporter({
    required CrashReporter delegate,
    PiiRedactor redactor = const PiiRedactor(),
  }) : _delegate = delegate,
       _redactor = redactor;

  final CrashReporter _delegate;
  final PiiRedactor _redactor;

  @override
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    return _delegate.captureError(
      error,
      stackTrace: stackTrace,
      context: _redactor.redactMap(context),
    );
  }

  @override
  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    return _delegate.captureMessage(
      _redactor.redactText(message),
      context: _redactor.redactMap(context),
    );
  }

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    return _delegate.addBreadcrumb(
      _redactor.redactText(message),
      data: _redactor.redactMap(data),
    );
  }

  @override
  Future<void> setUser(String? userId) => _delegate.setUser(userId);

  @override
  Future<void> setContext(String key, Map<String, Object?> value) {
    return _delegate.setContext(key, _redactor.redactMap(value));
  }
}
