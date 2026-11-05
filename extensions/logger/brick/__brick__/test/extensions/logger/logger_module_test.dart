import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/logger/file_log_sink.dart';
import 'package:{{app_name}}/extensions/logger/http_log_middleware.dart';
import 'package:{{app_name}}/extensions/logger/logger_config.dart';
import 'package:{{app_name}}/extensions/logger/logger_module.dart';
import 'package:{{app_name}}/extensions/logger/logger_support.dart';
import 'package:{{app_name}}/extensions/logger/log_level_controller.dart';
import 'package:{{app_name}}/extensions/logger/memory_log_sink.dart';
import 'package:{{app_name}}/extensions/logger/sink_pipeline.dart';

void main() {
  test('module registers the logger and its optional integrations', () async {
    final registry = GetItRegistry();
    registry.registerSingleton<AppFlavor>(AppFlavor.development);
    final reporter = FakeCrashReporter();
    registry.registerSingleton<CrashReporter>(reporter);
    final http = HttpPipeline();
    registry.registerSingleton<HttpPipeline>(http);
    final module = LoggerModule();

    module.register(registry);

    expect(registry.read<LoggerConfig>(), isA<LoggerConfig>());
    expect(registry.read<LoggerSupport>(), isA<LoggerSupport>());
    expect(registry.read<LogLevelController>().flavor, AppFlavor.development);
    expect(registry.read<MemoryLogSink>(), isA<MemoryLogSink>());
    expect(registry.read<AppLogger>(), isA<PipelineLogger>());
    expect(registry.read<FileLogSink>(), isA<FileLogSink>());

    final logger = registry.read<AppLogger>();
    final memory = registry.read<MemoryLogSink>();
    logger.warning('hello', data: const <String, Object?>{'id': 1});

    expect(memory.records.single.message, 'hello');
    expect(memory.records.single.level, LogLevel.warning);
    expect(reporter.breadcrumbs.single.message, 'hello');
    expect(http.middleware.whereType<HttpLogMiddleware>(), hasLength(1));

    await module.dispose();
  });

  test('falls back to a development level without the flavor extension', () {
    final registry = GetItRegistry();
    final module = LoggerModule();

    module.register(registry);

    final levels = registry.read<LogLevelController>();
    expect(levels.flavor, AppFlavor.development);
    expect(levels.level, LogLevel.trace);
    expect(registry.isRegistered<AppLogger>(), isTrue);
    expect(registry.isRegistered<FileLogSink>(), isTrue);
    expect(registry.isRegistered<CrashReporter>(), isFalse);
  });

  test('redaction can be disabled through config', () {
    final registry = GetItRegistry();
    final module = LoggerModule(
      config: const LoggerConfig(
        activeSinks: <LogSinkKind>{LogSinkKind.memory},
        redactionEnabled: false,
      ),
    );

    module.register(registry);
    registry.read<AppLogger>().info('contact andi@example.com');

    expect(
      registry.read<MemoryLogSink>().records.single.message,
      'contact andi@example.com',
    );
  });
}
