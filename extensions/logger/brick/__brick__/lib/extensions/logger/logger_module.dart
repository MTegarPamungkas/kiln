import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

import 'breadcrumb_sink.dart';
import 'console_logger.dart';
import 'file_log_sink.dart';
import 'http_log_middleware.dart';
import 'logger_config.dart';
import 'logger_support.dart';
import 'log_level_controller.dart';
import 'log_sink.dart';
import 'memory_log_sink.dart';
import 'redacting_sink.dart';
import 'sink_pipeline.dart';

/// Registers the logger, its configuration, and every enabled sink.
///
/// When the `flavor` extension is installed its [AppFlavor] decides the level;
/// otherwise a debug build falls back to development and a release build to
/// production. Crash breadcrumbs are added only when a [CrashReporter] exists.
final class LoggerModule extends KilnModule {
  LoggerModule({this.config});

  final LoggerConfig? config;
  SinkPipeline? _pipeline;

  @override
  String get id => 'logger';

  @override
  Set<String> get provides => const <String>{'logger'};

  @override
  Set<String> get optionalRequires => const <String>{
    'crash_reporter',
    'http_pipeline',
    'flavor',
  };

  @override
  void register(Registry registry) {
    final effectiveConfig = config ?? LoggerConfig.defaults;
    final clock = registry.readOrNull<Clock>() ?? const SystemClock();
    final flavor = registry.readOrNull<AppFlavor>() ?? _fallbackFlavor();
    final levels = LogLevelController(
      initialLevel: effectiveConfig.levelFor(flavor),
      flavor: flavor,
    );
    final memory = MemoryLogSink(capacity: effectiveConfig.memoryCapacity);
    final sinks = <LogSink>[];

    if (effectiveConfig.consoleSinkEnabled) {
      sinks.add(ConsoleLogSink());
    }
    FileLogSink? file;
    if (effectiveConfig.fileSinkEnabled && fileLogSinkSupported) {
      file = FileLogSink(
        fileName: effectiveConfig.fileName,
        maxFileBytes: effectiveConfig.maxFileBytes,
        maxFiles: effectiveConfig.maxFiles,
        clock: clock,
      );
      sinks.add(file);
    }
    if (effectiveConfig.memorySinkEnabled) {
      sinks.add(memory);
    }
    final reporter = registry.readOrNull<CrashReporter>();
    if (reporter != null && effectiveConfig.breadcrumbSinkEnabled) {
      sinks.add(BreadcrumbSink(reporter: reporter));
    }

    final redaction = effectiveConfig.redactionEnabled;
    final effectiveSinks = redaction
        ? <LogSink>[for (final sink in sinks) RedactingSink(sink)]
        : sinks;
    final pipeline = SinkPipeline(effectiveSinks);
    final logger = PipelineLogger(
      pipeline: pipeline,
      clock: clock,
      levelController: levels,
    );
    _pipeline = pipeline;

    registry
      ..registerSingleton<LoggerConfig>(effectiveConfig)
      ..registerSingleton<LoggerSupport>(LoggerSupport(config: effectiveConfig))
      ..registerSingleton<LogLevelController>(levels)
      ..registerSingleton<MemoryLogSink>(memory)
      ..registerSingleton<AppLogger>(logger);
    if (file != null) {
      registry.registerSingleton<FileLogSink>(file);
    }

    final httpPipeline = registry.readOrNull<HttpPipeline>();
    if (effectiveConfig.httpLoggingEnabled && httpPipeline != null) {
      httpPipeline.use(
        HttpLogMiddleware(logger: logger, clock: clock),
        priority: HttpLogMiddleware.priority,
      );
    }
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<LoggerSupport>().check();
  }

  @override
  Future<void> dispose() async {
    await _pipeline?.flush();
  }

  AppFlavor _fallbackFlavor() {
    return kDebugMode ? AppFlavor.development : AppFlavor.production;
  }
}
