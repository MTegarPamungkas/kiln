import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

/// Formats a [LogRecord] as human-readable text or as one JSON line.
///
/// Timestamps are always rendered in UTC with an ISO-8601 string, so the same
/// record produces the same output on every platform.
final class LogFormatter {
  const LogFormatter();

  /// Human-readable single line, suitable for a console or a flat file.
  String format(LogRecord record) {
    final buffer = StringBuffer()
      ..write(timestamp(record.timestamp))
      ..write(' [')
      ..write(levelLabel(record.level))
      ..write('] ')
      ..write(record.message);
    final error = record.error;
    if (error != null) {
      buffer
        ..write(' | error: ')
        ..write(error);
    }
    final data = record.data;
    if (data != null && data.isNotEmpty) {
      buffer
        ..write(' | data: ')
        ..write(_encode(data));
    }
    return buffer.toString();
  }

  /// One JSON object per record, the shape expected by log collectors.
  String formatJson(LogRecord record) {
    final data = record.data;
    final payload = <String, Object?>{
      'timestamp': timestamp(record.timestamp),
      'level': record.level.name,
      'message': record.message,
      if (record.error != null) 'error': '${record.error}',
      if (record.stackTrace != null) 'stackTrace': '${record.stackTrace}',
      if (data != null) 'data': _jsonSafe(data),
    };
    return jsonEncode(payload);
  }

  /// Stable timestamp used by both text and JSON output.
  static String timestamp(DateTime value) => value.toUtc().toIso8601String();

  /// Upper-case label for a level.
  static String levelLabel(LogLevel level) {
    return switch (level) {
      LogLevel.trace => 'TRACE',
      LogLevel.debug => 'DEBUG',
      LogLevel.info => 'INFO',
      LogLevel.warning => 'WARNING',
      LogLevel.error => 'ERROR',
    };
  }

  String _encode(Object? value) {
    try {
      return jsonEncode(_jsonSafe(value));
    } on Object {
      return '$value';
    }
  }

  Object? _jsonSafe(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) {
      return timestamp(value);
    }
    if (value is Map) {
      return <String, Object?>{
        for (final entry in value.entries)
          '${entry.key}': _jsonSafe(entry.value),
      };
    }
    if (value is Iterable) {
      return value.map(_jsonSafe).toList(growable: false);
    }
    return '$value';
  }
}
