import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// A destination for [LogRecord]s.
///
/// A sink should only write the record it receives. Filtering by level happens
/// before a record reaches the pipeline, so every attached sink sees the same
/// stream of records.
abstract interface class LogSink {
  /// Writes one record, synchronously or asynchronously.
  FutureOr<void> write(LogRecord record);

  /// Completes when every write accepted so far has been persisted.
  FutureOr<void> flush();
}

/// Builds a sink, used by wiring code and tests.
typedef LogSinkFactory = LogSink Function();

/// Receives a failure raised by one sink so logging can keep going.
///
/// The handler must not log through the pipeline that reported the failure,
/// otherwise a broken sink would recurse.
typedef SinkFailureWriter = void Function(
  String message,
  Object error,
  StackTrace stackTrace,
);
