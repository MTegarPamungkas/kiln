// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';

/// [CrashReporter] decorator that guarantees reporting never throws.
///
/// A crash reporter must never become the crash. Every delegate call is
/// guarded; the first failure is written to [logger] once and later failures
/// are swallowed quietly so a broken transport cannot flood the log or the app.
final class SafeCrashReporter implements CrashReporter {
  SafeCrashReporter({required CrashReporter delegate, AppLogger? logger})
    : _delegate = delegate,
      _logger = logger;

  final CrashReporter _delegate;
  final AppLogger? _logger;
  bool _reportedFailure = false;

  @override
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    return _guard(
      () => _delegate.captureError(
        error,
        stackTrace: stackTrace,
        context: context,
      ),
    );
  }

  @override
  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    return _guard(
      () => _delegate.captureMessage(message, context: context),
    );
  }

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    return _guard(() => _delegate.addBreadcrumb(message, data: data));
  }

  @override
  Future<void> setUser(String? userId) => _guard(
    () => _delegate.setUser(userId),
  );

  @override
  Future<void> setContext(String key, Map<String, Object?> value) => _guard(
    () => _delegate.setContext(key, value),
  );

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error, stackTrace) {
      _logOnce(error, stackTrace);
    }
  }

  void _logOnce(Object error, StackTrace stackTrace) {
    if (_reportedFailure) {
      return;
    }
    _reportedFailure = true;
    _logger?.warning(
      'Crash reporting failed; further reporting errors will be suppressed.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
