import 'package:kiln_core/kiln_core.dart';

import 'file_log_sink.dart';
import 'logger_config.dart';

typedef LoggerFileProbe = Future<bool> Function();

/// Reports which logger sinks are usable on this platform.
///
/// A missing file sink does not make the extension unsupported; the remaining
/// sinks keep working and the support details expose the degradation.
final class LoggerSupport {
  LoggerSupport({required this.config, LoggerFileProbe? fileProbe})
    : fileProbe = fileProbe ?? probeFileLogSink;

  final LoggerConfig config;
  final LoggerFileProbe fileProbe;
  SupportInfo? _last;

  Future<SupportInfo> check() async {
    final last = _last;
    if (last != null) {
      return last;
    }
    final info = await _probe();
    _last = info;
    return info;
  }

  void clear() => _last = null;

  Future<SupportInfo> _probe() async {
    final problem = config.validate();
    if (problem != null) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: problem.message,
        details: <String, Object?>{'code': problem.code.value},
      );
    }
    var fileSink = false;
    if (config.fileSinkEnabled && fileLogSinkSupported) {
      try {
        fileSink = await fileProbe();
      } on Object {
        fileSink = false;
      }
    }
    final degraded = config.fileSinkEnabled && !fileSink;
    return SupportInfo.supported(
      message: degraded
          ? 'File logging is unavailable; other sinks remain active.'
          : 'Supported',
      details: <String, Object?>{
        'console': config.consoleSinkEnabled,
        'file': fileSink,
        'memory': config.memorySinkEnabled,
        'breadcrumb': config.breadcrumbSinkEnabled,
        'http': config.httpLoggingEnabled,
      },
    );
  }
}
