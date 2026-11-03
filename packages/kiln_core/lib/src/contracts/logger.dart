/// Severity of a log entry, from least to most severe.
enum LogLevel { trace, debug, info, warning, error }

/// One immutable log entry handed to a sink.
final class LogRecord {
  const LogRecord({
    required this.level,
    required this.message,
    required this.timestamp,
    this.error,
    this.stackTrace,
    this.data,
  });

  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, Object?>? data;
}

/// Application logging contract.
abstract class AppLogger {
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  });

  void trace(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) => log(
    LogLevel.trace,
    message,
    error: error,
    stackTrace: stackTrace,
    data: data,
  );

  void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) => log(
    LogLevel.debug,
    message,
    error: error,
    stackTrace: stackTrace,
    data: data,
  );

  void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) => log(
    LogLevel.info,
    message,
    error: error,
    stackTrace: stackTrace,
    data: data,
  );

  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) => log(
    LogLevel.warning,
    message,
    error: error,
    stackTrace: stackTrace,
    data: data,
  );

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) => log(
    LogLevel.error,
    message,
    error: error,
    stackTrace: stackTrace,
    data: data,
  );
}
