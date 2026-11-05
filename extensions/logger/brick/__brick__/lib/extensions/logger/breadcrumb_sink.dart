import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'log_sink.dart';

/// Forwards warning and error records to a [CrashReporter] as breadcrumbs.
///
/// The context shipped with a breadcrumb always includes the level, plus the
/// record data and a textual error when present.
final class BreadcrumbSink implements LogSink {
  BreadcrumbSink({
    required this.reporter,
    this.minimumLevel = LogLevel.warning,
  });

  final CrashReporter reporter;
  final LogLevel minimumLevel;

  @override
  FutureOr<void> write(LogRecord record) {
    if (record.level.index < minimumLevel.index) {
      return null;
    }
    final data = <String, Object?>{
      ...?record.data,
      if (record.error != null) 'error': '${record.error}',
      'level': record.level.name,
    };
    return reporter.addBreadcrumb(record.message, data: data);
  }

  @override
  FutureOr<void> flush() => null;
}
