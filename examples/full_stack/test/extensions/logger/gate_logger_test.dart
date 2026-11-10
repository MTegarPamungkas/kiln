import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/logger/gate_logger.dart';
import 'package:full_stack/extensions/logger/log_level_controller.dart';
import 'package:full_stack/extensions/logger/memory_log_sink.dart';

Gate _gate({AppFlavor flavor = AppFlavor.development, MemoryLogSink? memory}) {
  final registry = GetItRegistry();
  registry
    ..registerSingleton<LogLevelController>(
      LogLevelController(initialLevel: LogLevel.info, flavor: flavor),
    )
    ..registerSingleton<MemoryLogSink>(memory ?? MemoryLogSink(capacity: 10));
  return Gate(registry);
}

void main() {
  test('setLogLevel changes the level through the gate', () async {
    final gate = _gate();

    final result = await gate.setLogLevel(LogLevel.debug);

    expect(result.isOk, isTrue);
    expect(gate.logLevel, LogLevel.debug);
  });

  test('setLogLevel in production returns Err', () async {
    final gate = _gate(flavor: AppFlavor.production);

    final result = await gate.setLogLevel(LogLevel.debug);

    expect(result.failureOrNull?.code, FailureCode.validationUnsupportedValue);
    expect(gate.logLevel, LogLevel.warning);
  });

  test('logRecords and clearLogs read and reset the buffer', () {
    final memory = MemoryLogSink(capacity: 10);
    final gate = _gate(memory: memory);

    memory.write(
      LogRecord(
        level: LogLevel.warning,
        message: 'boom',
        timestamp: DateTime.utc(2026, 11, 4),
      ),
    );

    expect(gate.logRecords, hasLength(1));
    expect(gate.logRecords.single.message, 'boom');

    gate.clearLogs();
    expect(gate.logRecords, isEmpty);
  });
}
