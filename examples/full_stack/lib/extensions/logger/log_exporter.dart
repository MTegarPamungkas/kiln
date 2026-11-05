import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

import 'file_log_sink.dart';
import 'log_formatter.dart';
import 'memory_log_sink.dart';
import 'redacting_sink.dart';

/// Collects memory records and file content into one redacted report.
///
/// Redaction is applied again at export time even when the sinks already
/// received redacted records, which protects reports assembled from older or
/// third-party sinks.
final class LogExporter {
  LogExporter({
    required this.memory,
    this.file,
    this.formatter = const LogFormatter(),
    this.redactor = const PiiRedactor(),
    this.clock = const SystemClock(),
  });

  final MemoryLogSink memory;
  final FileLogSink? file;
  final LogFormatter formatter;
  final PiiRedactor redactor;
  final Clock clock;

  /// Builds a plain-text report with a memory section and, when attached, a
  /// file section.
  Future<String> export() async {
    final records = memory.records;
    final buffer = StringBuffer()
      ..writeln('# Kiln log export')
      ..writeln('generated: ${LogFormatter.timestamp(clock.now())}')
      ..writeln()
      ..writeln('## Memory (${records.length} records)');
    for (final record in records) {
      buffer.writeln(
        formatter.format(redactLogRecord(record, redactor: redactor)),
      );
    }
    final sink = file;
    if (sink != null) {
      buffer
        ..writeln()
        ..writeln('## File');
      final content = await sink.read();
      for (final line in const LineSplitter().convert(content)) {
        buffer.writeln(redactor.redactText(line));
      }
    }
    return buffer.toString();
  }
}
