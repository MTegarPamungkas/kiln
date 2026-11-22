import 'dart:async';
import 'dart:collection';

import 'package:kiln_core/kiln_core.dart';

import 'log_sink.dart';

/// Default ceiling for one string in a log record.
const int defaultMaxRecordTextLength = 16384;

/// Default nesting ceiling for structured log data.
const int defaultMaxRecordDepth = 12;

/// Default number of map entries and list items allowed across one record.
const int defaultMaxRecordEntries = 200;

/// Marker replacing a value that exceeded a depth or entry budget.
const String recordTruncationMarker = '[truncated]';

/// Bounds every field of [record] so one log call cannot exhaust a sink.
///
/// Redaction removes personal data, but it is optional; this limiter runs for
/// every record regardless. Long strings keep their prefix and gain a
/// `...[+N chars]` suffix, structured data is bounded by depth and total entry
/// count, and cycles are replaced instead of followed.
LogRecord limitLogRecord(
  LogRecord record, {
  int maxTextLength = defaultMaxRecordTextLength,
  int maxDepth = defaultMaxRecordDepth,
  int maxEntries = defaultMaxRecordEntries,
}) {
  if (maxTextLength < 1 || maxDepth < 0 || maxEntries < 1) {
    throw ArgumentError('Log record limits must be positive.');
  }
  final budget = _RecordBudget(maxEntries);
  final seen = HashSet<Object>.identity();
  Object? limitValue(Object? value, int depth) {
    if (depth > maxDepth) {
      return recordTruncationMarker;
    }
    if (value is String) {
      return _limitText(value, maxTextLength);
    }
    if (value is Map) {
      if (!seen.add(value)) {
        return recordTruncationMarker;
      }
      try {
        final output = <String, Object?>{};
        for (final entry in value.entries) {
          if (!budget.take()) {
            output[recordTruncationMarker] = recordTruncationMarker;
            break;
          }
          output[_limitText('${entry.key}', maxTextLength)] = limitValue(
            entry.value,
            depth + 1,
          );
        }
        return output;
      } finally {
        seen.remove(value);
      }
    }
    if (value is Iterable) {
      if (!seen.add(value)) {
        return recordTruncationMarker;
      }
      try {
        final output = <Object?>[];
        for (final item in value) {
          if (!budget.take()) {
            output.add(recordTruncationMarker);
            break;
          }
          output.add(limitValue(item, depth + 1));
        }
        return output;
      } finally {
        seen.remove(value);
      }
    }
    if (value == null || value is num || value is bool) {
      return value;
    }
    return _limitText('$value', maxTextLength);
  }

  final error = record.error;
  final stackTrace = record.stackTrace;
  final data = record.data;
  return LogRecord(
    level: record.level,
    message: _limitText(record.message, maxTextLength),
    timestamp: record.timestamp,
    error: error == null ? null : _limitText('$error', maxTextLength),
    stackTrace: stackTrace == null
        ? null
        : StackTrace.fromString(
            _limitText('$stackTrace', maxTextLength),
          ),
    data: data == null ? null : limitValue(data, 0) as Map<String, Object?>,
  );
}

/// Decorator that bounds a record before delegating to another sink.
///
/// The module puts this under every sink, so it also applies when
/// `redactionEnabled` is false. Wrap it inside a redacting sink when both are
/// needed: bounding first keeps the redaction work proportional to the limit.
final class LimitedSink implements LogSink {
  LimitedSink(
    this.sink, {
    this.maxTextLength = defaultMaxRecordTextLength,
    this.maxDepth = defaultMaxRecordDepth,
    this.maxEntries = defaultMaxRecordEntries,
  }) : assert(maxTextLength > 0),
       assert(maxDepth >= 0),
       assert(maxEntries > 0);

  final LogSink sink;
  final int maxTextLength;
  final int maxDepth;
  final int maxEntries;

  @override
  FutureOr<void> write(LogRecord record) {
    return sink.write(
      limitLogRecord(
        record,
        maxTextLength: maxTextLength,
        maxDepth: maxDepth,
        maxEntries: maxEntries,
      ),
    );
  }

  @override
  FutureOr<void> flush() => sink.flush();
}

String _limitText(String value, int maxLength) {
  if (value.length <= maxLength) {
    return value;
  }
  final suffix = '...[+${value.length - maxLength} chars]';
  final keep = maxLength - suffix.length;
  if (keep <= 0) {
    return value.substring(0, maxLength);
  }
  return '${value.substring(0, keep)}$suffix';
}

final class _RecordBudget {
  _RecordBudget(this._remaining);

  int _remaining;

  bool take() {
    if (_remaining <= 0) {
      return false;
    }
    _remaining--;
    return true;
  }
}
