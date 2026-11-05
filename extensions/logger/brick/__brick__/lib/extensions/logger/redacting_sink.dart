import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'log_sink.dart';

/// Returns a copy of [record] with personal data replaced.
///
/// The message, the textual error, and every data value are passed through
/// [PiiRedactor]. Stack traces are kept because they help reproduce failures
/// and do not normally carry user input.
LogRecord redactLogRecord(
  LogRecord record, {
  PiiRedactor redactor = const PiiRedactor(),
}) {
  final error = record.error;
  final data = record.data;
  return LogRecord(
    level: record.level,
    message: redactor.redactText(record.message),
    timestamp: record.timestamp,
    error: error == null ? null : redactor.redactText('$error'),
    stackTrace: record.stackTrace,
    data: data == null ? null : redactor.redactMap(data),
  );
}

/// Decorator that redacts a record before delegating to another sink.
final class RedactingSink implements LogSink {
  RedactingSink(this.sink, {this.redactor = const PiiRedactor()});

  final LogSink sink;
  final PiiRedactor redactor;

  @override
  FutureOr<void> write(LogRecord record) {
    return sink.write(redactLogRecord(record, redactor: redactor));
  }

  @override
  FutureOr<void> flush() => sink.flush();
}
