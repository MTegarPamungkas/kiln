import 'dart:async';
import 'dart:developer' as developer;

import 'package:kiln_core/kiln_core.dart';

import 'log_formatter.dart';
import 'log_level_controller.dart';
import 'log_sink.dart';

/// Writes a formatted line to the console.
void _defaultConsoleWriter(String line) {
  developer.log(line, name: 'app');
}

/// [LogSink] that prints formatted records with an injectable writer.
final class ConsoleLogSink implements LogSink {
  ConsoleLogSink({
    this.formatter = const LogFormatter(),
    void Function(String line)? writer,
  }) : _writer = writer ?? _defaultConsoleWriter;

  final LogFormatter formatter;
  final void Function(String line) _writer;

  @override
  FutureOr<void> write(LogRecord record) {
    _writer(formatter.format(record));
    return null;
  }

  @override
  FutureOr<void> flush() => null;
}

/// [AppLogger] that prints human-readable lines to the console.
///
/// Use it standalone in tests or small tools; the module wires a
/// [ConsoleLogSink] into the full pipeline instead.
final class ConsoleLogger extends AppLogger {
  ConsoleLogger({
    ConsoleLogSink? sink,
    void Function(String line)? write,
    this.levelController,
    this.minimumLevel = LogLevel.trace,
    this.clock = const SystemClock(),
  }) : assert(
         sink == null || write == null,
         'Pass either a sink or a writer, not both.',
       ),
       sink = sink ?? ConsoleLogSink(writer: write);

  final ConsoleLogSink sink;
  final LogLevelController? levelController;
  final LogLevel minimumLevel;
  final Clock clock;

  /// Current threshold, read from the controller when one is attached.
  LogLevel get level => levelController?.level ?? minimumLevel;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    if (level.index < this.level.index) {
      return;
    }
    final result = sink.write(
      LogRecord(
        level: level,
        message: message,
        timestamp: clock.now(),
        error: error,
        stackTrace: stackTrace,
        data: data,
      ),
    );
    if (result is Future<void>) {
      unawaited(result);
    }
  }
}
