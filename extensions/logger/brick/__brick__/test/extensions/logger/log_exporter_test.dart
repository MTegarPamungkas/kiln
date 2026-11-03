import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/logger/file_log_sink.dart';
import 'package:{{app_name}}/extensions/logger/log_exporter.dart';
import 'package:{{app_name}}/extensions/logger/memory_log_sink.dart';

void main() {
  test('merges memory and file logs in redacted form', () async {
    final directory = await Directory.systemTemp.createTemp('kiln_logger_export_');
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    final clock = FixedClock(DateTime.utc(2026, 2, 3, 4, 5, 6));
    final memory = MemoryLogSink();
    memory.write(
      LogRecord(
        level: LogLevel.info,
        message: 'memory andi@example.com',
        timestamp: clock.now(),
      ),
    );
    final file = FileLogSink(directoryPath: directory.path, clock: clock);
    await file.write(
      LogRecord(
        level: LogLevel.warning,
        message: 'file Bearer abc.def',
        timestamp: clock.now(),
      ),
    );
    await file.flush();

    final exporter = LogExporter(
      memory: memory,
      file: file,
      clock: clock,
    );
    final report = await exporter.export();

    expect(report, contains('generated: 2026-02-03T04:05:06.000Z'));
    expect(report, contains('## Memory (1 records)'));
    expect(report, contains('memory [redacted]'));
    expect(report, contains('## File'));
    expect(report, contains('file Bearer [redacted]'));
    expect(report, isNot(contains('andi@example.com')));
    expect(report, isNot(contains('abc.def')));
  });

  test('exports memory only when no file sink is attached', () async {
    final memory = MemoryLogSink()
      ..write(
        LogRecord(
          level: LogLevel.info,
          message: 'only memory',
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      );
    final exporter = LogExporter(memory: memory);

    final report = await exporter.export();

    expect(report, contains('only memory'));
    expect(report, isNot(contains('## File')));
  });
}
