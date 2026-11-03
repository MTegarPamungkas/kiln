import 'dart:async';
import 'dart:collection';

import 'package:kiln_core/kiln_core.dart';

import 'log_sink.dart';

/// Keeps the most recent records in a ring buffer.
///
/// The buffer backs the debug log page, bug reports, and tests. It never grows
/// past [capacity]; the oldest record is dropped first.
final class MemoryLogSink implements LogSink {
  MemoryLogSink({this.capacity = 200}) : assert(capacity > 0);

  final int capacity;
  final Queue<LogRecord> _records = Queue<LogRecord>();

  /// Records from oldest to newest.
  List<LogRecord> get records => List<LogRecord>.unmodifiable(_records);

  int get length => _records.length;

  bool get isEmpty => _records.isEmpty;

  bool get isNotEmpty => _records.isNotEmpty;

  @override
  FutureOr<void> write(LogRecord record) {
    _records.addLast(record);
    while (_records.length > capacity) {
      _records.removeFirst();
    }
    return null;
  }

  /// Removes every buffered record.
  void clear() => _records.clear();

  @override
  FutureOr<void> flush() => null;
}
