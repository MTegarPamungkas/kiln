import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'log_formatter.dart';
import 'log_sink.dart';

/// File logging is only available where `dart:io` exists.
const bool fileLogSinkSupported = false;

/// Stub used when the application is compiled for the web.
///
/// The module checks [fileLogSinkSupported] before constructing the sink; the
/// no-op methods keep this type safe to compile and reference everywhere.
final class FileLogSink implements LogSink {
  FileLogSink({
    this.directoryPath,
    this.fileName = 'app.log',
    this.maxFileBytes = 262144,
    this.maxFiles = 3,
    this.formatter = const LogFormatter(),
    this.clock = const SystemClock(),
    this.onFailure,
  }) : assert(maxFileBytes > 0),
       assert(maxFiles > 0);

  final String? directoryPath;
  final String fileName;
  final int maxFileBytes;
  final int maxFiles;
  final LogFormatter formatter;
  final Clock clock;
  final SinkFailureWriter? onFailure;

  /// Last failure reported by this sink, if any.
  Object? lastFailure;

  @override
  FutureOr<void> write(LogRecord record) => null;

  @override
  FutureOr<void> flush() => null;

  /// Returns the content of every retained file; empty on the web.
  Future<String> read() async => '';
}
