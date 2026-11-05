import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/crash_report/safe_crash_reporter.dart';

/// A delegate that fails every call, used to prove [SafeCrashReporter] contains it.
final class _ThrowingReporter implements CrashReporter {
  @override
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) async => throw StateError('transport down');

  @override
  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) async => throw StateError('transport down');

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  }) async => throw StateError('transport down');

  @override
  Future<void> setUser(String? userId) async => throw StateError('down');

  @override
  Future<void> setContext(
    String key,
    Map<String, Object?> value,
  ) async => throw StateError('down');
}

final class _CountingLogger extends AppLogger {
  int warnings = 0;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    if (level == LogLevel.warning) {
      warnings++;
    }
  }
}

void main() {
  group('SafeCrashReporter', () {
    test('never rethrows a delegate failure', () async {
      final reporter = SafeCrashReporter(delegate: _ThrowingReporter());

      await reporter.captureError(StateError('x'));
      await reporter.captureMessage('m');
      await reporter.addBreadcrumb('b');
      await reporter.setUser('u');
      await reporter.setContext('k', const <String, Object?>{});

      expect(true, isTrue);
    });

    test('logs the first failure only once', () async {
      final logger = _CountingLogger();
      final reporter = SafeCrashReporter(
        delegate: _ThrowingReporter(),
        logger: logger,
      );

      await reporter.captureError(StateError('one'));
      await reporter.captureError(StateError('two'));
      await reporter.captureError(StateError('three'));

      expect(logger.warnings, 1);
    });
  });
}
