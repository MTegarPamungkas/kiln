import 'package:kiln_core/kiln_core.dart';

/// Logger settings installed by the module.
///
/// Levels are typed per standard flavor, the active sink set decides what the
/// module wires, and redaction can be disabled for a local debugging session.
final class LoggerConfig {
  const LoggerConfig({
    this.developmentLevel = LogLevel.trace,
    this.stagingLevel = LogLevel.debug,
    this.productionLevel = LogLevel.warning,
    this.activeSinks = defaultSinks,
    this.redactionEnabled = true,
    this.memoryCapacity = 200,
    this.fileName = 'app.log',
    this.maxFileBytes = 262144,
    this.maxFiles = 3,
    this.httpLoggingEnabled = true,
  });

  /// Sinks enabled by the install prompts; file output follows `file_sink`.
  static const Set<LogSinkKind> defaultSinks = <LogSinkKind>{
    LogSinkKind.console,
    LogSinkKind.memory,
    LogSinkKind.breadcrumb,
    LogSinkKind.file,
  };

  /// Settings rendered from the install prompts.
  static const defaults = LoggerConfig();

  final LogLevel developmentLevel;
  final LogLevel stagingLevel;
  final LogLevel productionLevel;
  final Set<LogSinkKind> activeSinks;
  final bool redactionEnabled;
  final int memoryCapacity;
  final String fileName;
  final int maxFileBytes;
  final int maxFiles;
  final bool httpLoggingEnabled;

  bool get fileSinkEnabled => activeSinks.contains(LogSinkKind.file);

  bool get memorySinkEnabled => activeSinks.contains(LogSinkKind.memory);

  bool get consoleSinkEnabled => activeSinks.contains(LogSinkKind.console);

  bool get breadcrumbSinkEnabled =>
      activeSinks.contains(LogSinkKind.breadcrumb);

  /// Level for a known flavor, or the production level for a custom one.
  LogLevel levelFor(AppFlavor flavor) {
    if (flavor == AppFlavor.development) {
      return developmentLevel;
    }
    if (flavor == AppFlavor.staging) {
      return stagingLevel;
    }
    return productionLevel;
  }
}

/// Kind of sink the module may wire into the pipeline.
enum LogSinkKind { console, memory, file, breadcrumb }
