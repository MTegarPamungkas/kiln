import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/logger/logger_config.dart';

void main() {
  test('defaults carry the rendered prompts', () {
    const config = LoggerConfig.defaults;

    expect(config.activeSinks, contains(LogSinkKind.console));
    expect(config.activeSinks, contains(LogSinkKind.memory));
    expect(config.activeSinks, contains(LogSinkKind.breadcrumb));
    expect(config.activeSinks, contains(LogSinkKind.file));
    expect(config.fileSinkEnabled, isTrue);
    expect(config.httpLoggingEnabled, isTrue);
    expect(config.redactionEnabled, isTrue);
    expect(config.memoryCapacity, 200);
  });

  test('levels are typed per flavor', () {
    const config = LoggerConfig.defaults;

    expect(config.levelFor(AppFlavor.development), LogLevel.trace);
    expect(config.levelFor(AppFlavor.staging), LogLevel.debug);
    expect(config.levelFor(AppFlavor.production), LogLevel.warning);
    expect(config.levelFor(const AppFlavor('qa')), config.productionLevel);
  });

  test('active sinks drive the convenience getters', () {
    const config = LoggerConfig(
      activeSinks: <LogSinkKind>{LogSinkKind.memory},
      developmentLevel: LogLevel.info,
    );

    expect(config.memorySinkEnabled, isTrue);
    expect(config.consoleSinkEnabled, isFalse);
    expect(config.fileSinkEnabled, isFalse);
    expect(config.breadcrumbSinkEnabled, isFalse);
    expect(config.levelFor(AppFlavor.development), LogLevel.info);
  });
}
