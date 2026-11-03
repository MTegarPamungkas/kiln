import 'package:kiln_core/kiln_core.dart';

/// [AppLogger] that keeps every record so a test can assert on it.
final class RecordingLogger extends AppLogger {
  RecordingLogger({Clock? clock}) : _clock = clock ?? const SystemClock();

  final Clock _clock;
  final List<LogRecord> records = <LogRecord>[];

  List<String> get messages =>
      records.map((record) => record.message).toList(growable: false);

  List<LogLevel> get levels =>
      records.map((record) => record.level).toList(growable: false);

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    records.add(
      LogRecord(
        level: level,
        message: message,
        timestamp: _clock.now(),
        error: error,
        stackTrace: stackTrace,
        data: data,
      ),
    );
  }
}
