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

  test('drops oldest pending records when maxPending is exceeded', () async {
    final directory = await Directory.systemTemp.createTemp('kiln_logger_cap_');
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    final sink = FileLogSink(
      directoryPath: directory.path,
      maxPending: 3,
    );

    for (var i = 0; i < 10; i++) {
      // Fire synchronously without awaiting so records queue up in memory.
      // ignore: unawaited_futures
      sink.write(
        LogRecord(
          level: LogLevel.info,
          message: 'burst-$i',
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      );
    }
    await sink.flush();

    expect(sink.droppedCount, greaterThan(0));
    final content = await sink.read();
    expect(content, contains('burst-9'));
  });

  test('keeps queued records across a transient write failure', () async {
    final directory = await Directory.systemTemp.createTemp('kiln_logger_retry_');
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    // A file where the log directory should be makes the first write fail.
    final blocker = File('${directory.path}${Platform.pathSeparator}blocked')
      ..writeAsStringSync('x');
    final failures = <String>[];
    final sink = FileLogSink(
      directoryPath: '${blocker.path}${Platform.pathSeparator}logs',
      writeRetryDelay: const Duration(milliseconds: 1),
      onFailure: (message, error, stackTrace) {
        failures.add(message);
        if (blocker.existsSync()) {
          blocker.deleteSync();
        }
      },
    );

    await sink.write(
      LogRecord(
        level: LogLevel.info,
        message: 'survives',
        timestamp: DateTime.utc(2026, 1, 1),
      ),
    );
    await sink.flush();

    expect(failures, hasLength(1));
    expect(sink.droppedCount, 0);
    expect(await sink.read(), contains('survives'));
  });

  test('drops and counts records after repeated write failures', () async {
    final directory = await Directory.systemTemp.createTemp('kiln_logger_fail_');
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    final blocker = File('${directory.path}${Platform.pathSeparator}blocked')
      ..writeAsStringSync('x');
    final failures = <String>[];
    final sink = FileLogSink(
      directoryPath: '${blocker.path}${Platform.pathSeparator}logs',
      maxWriteAttempts: 2,
      writeRetryDelay: const Duration(milliseconds: 1),
      onFailure: (message, error, stackTrace) => failures.add(message),
    );

    for (var i = 0; i < 3; i++) {
      // ignore: unawaited_futures
      sink.write(
        LogRecord(
          level: LogLevel.info,
          message: 'lost-$i',
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      );
    }
    await sink.flush().timeout(const Duration(seconds: 5));

    expect(failures, hasLength(2));
    expect(failures.last, contains('dropped'));
    expect(sink.droppedCount, 3);
    expect(sink.lastFailure, isNotNull);
  });
}
