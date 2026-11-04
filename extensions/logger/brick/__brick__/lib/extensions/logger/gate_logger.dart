import 'package:kiln_core/kiln_core.dart';

import 'log_level_controller.dart';
import 'memory_log_sink.dart';

/// Gate verbs for the logging capability.
///
/// Augments the kiln_core [Gate] facade so the application reads and changes
/// the runtime log level with a single call returning a [Result], and reads
/// the buffered records for its own log viewer. The SDK owns the state, not
/// the UI.
extension GateLoggerX on Gate {
  LogLevelController get logLevelController => use<LogLevelController>();

  /// Current log threshold; records below it are dropped.
  LogLevel get logLevel => logLevelController.level;

  /// Raises or lowers the threshold. Production flavors return an [Err].
  Future<Result<void>> setLogLevel(LogLevel level) =>
      call<void>(() => logLevelController.setLevel(level));

  /// Buffered records from oldest to newest, for an app-owned log viewer.
  List<LogRecord> get logRecords => use<MemoryLogSink>().records;

  /// Removes every buffered record.
  void clearLogs() => use<MemoryLogSink>().clear();
}
