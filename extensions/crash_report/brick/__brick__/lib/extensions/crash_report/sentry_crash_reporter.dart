// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';

import 'crash_report_failure_mapper.dart';
import 'crash_report_gateway.dart';

/// [CrashReporter] implementation that forwards sanitized data to a gateway.
///
/// The consent and PII decorators wrap this class, so by the time a call
/// reaches here it is already allowed and scrubbed. Gateway transport errors
/// are mapped to a [Failure] so the outer [SafeCrashReporter] can contain them.
final class SentryCrashReporter implements CrashReporter {
  SentryCrashReporter({
    required CrashReportGateway gateway,
    CrashReportFailureMapper failureMapper = const CrashReportFailureMapper(),
  }) : _gateway = gateway,
       _failureMapper = failureMapper;

  final CrashReportGateway _gateway;
  final CrashReportFailureMapper _failureMapper;

  @override
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    return _run(
      () => _gateway.captureError(
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
    _requireText(message, 'Crash message');
    return _run(() => _gateway.captureMessage(message, context: context));
  }

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    _requireText(message, 'Crash breadcrumb');
    return _run(() => _gateway.addBreadcrumb(message, data: data));
  }

  @override
  Future<void> setUser(String? userId) {
    return _run(() => _gateway.setUser(userId));
  }

  @override
  Future<void> setContext(String key, Map<String, Object?> value) {
    _requireText(key, 'Crash context key');
    return _run(() => _gateway.setContext(key, value));
  }

  /// Flushes queued events; not part of the [CrashReporter] contract.
  Future<void> flush() => _run(_gateway.flush);

  /// Flushes and shuts the SDK down; not part of the contract.
  Future<void> close() => _run(_gateway.close);

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error, stackTrace) {
      throw _failureMapper.map(error, stackTrace: stackTrace);
    }
  }

  void _requireText(String value, String label) {
    if (value.trim().isEmpty) {
      throw Failure(
        code: FailureCode.validationInvalidInput,
        message: '$label must not be empty.',
        kind: FailureKind.validation,
      );
    }
  }
}
