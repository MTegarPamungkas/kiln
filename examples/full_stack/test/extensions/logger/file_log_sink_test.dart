import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/logger/file_log_sink.dart';

void main() {
  test('writes records and rotates files', () async {
    final directory = await Directory.systemTemp.createTemp('kiln_logger_file_');
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    final clock = FixedClock(DateTime.utc(2026, 1, 2, 3, 4, 5));
    final sink = FileLogSink(
      directoryPath: directory.path,
      maxFileBytes: 180,
      maxFiles: 3,
      clock: clock,
    );

    for (var index = 0; index < 12; index++) {
      clock.advance(const Duration(milliseconds: 1));
      await sink.write(
        LogRecord(
          level: LogLevel.info,
          message: 'entry $index',
          timestamp: clock.now(),
        ),
      );
    }
    await sink.flush();

    final current = File(
      '${directory.path}${Platform.pathSeparator}app.log',
    );
    expect(await current.exists(), isTrue);
    expect(await current.length(), greaterThan(0));
    expect(
      File('${current.path}.1').existsSync(),
      isTrue,
      reason: 'the current file should rotate once it is full',
    );
    final files = directory
        .listSync()
        .whereType<File>()
        .toList(growable: false);
    expect(files.length, lessThanOrEqualTo(3));

    final content = await sink.read();
    expect(content, contains('entry 11'));
    expect(content, contains('[INFO]'));
  });

  test('uses a custom file name', () async {
    final directory = await Directory.systemTemp.createTemp('kiln_logger_name_');
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    final sink = FileLogSink(
      directoryPath: directory.path,
      fileName: 'debug.txt',
    );

    await sink.write(
      LogRecord(
        level: LogLevel.debug,
        message: 'named',
        timestamp: DateTime.utc(2026, 1, 1),
      ),
    );
    await sink.flush();

    final file = File(
      '${directory.path}${Platform.pathSeparator}debug.txt',
    );
    expect(await file.exists(), isTrue);
    expect(await file.readAsString(), contains('[DEBUG] named'));
  });
}
