import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/logger/logger_config.dart';
import 'package:full_stack/extensions/logger/logger_module.dart';
import 'package:full_stack/extensions/logger/memory_log_sink.dart';
import 'package:full_stack/extensions/logger/record_size_limit.dart';
import 'package:full_stack/extensions/logger/log_sink.dart';

void main() {
  LogRecord record({
    String message = 'message',
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    return LogRecord(
      level: LogLevel.info,
      message: message,
      timestamp: DateTime.utc(2026, 11, 21),
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  test('bounds every textual field and data string', () {
    final limited = limitLogRecord(
      record(
        message: 'm' * 1000,
        error: 'e' * 1000,
        stackTrace: StackTrace.fromString('s' * 1000),
        data: <String, Object?>{'key': 'v' * 1000},
      ),
      maxTextLength: 100,
    );

    expect(limited.message.length, lessThanOrEqualTo(100));
    expect(limited.message, startsWith('m'));
    expect((limited.error! as String).length, lessThanOrEqualTo(100));
    expect(limited.stackTrace.toString().length, lessThanOrEqualTo(100));
    expect((limited.data!['key']! as String).length, lessThanOrEqualTo(100));
  });

  test('keeps short fields untouched', () {
    final limited = limitLogRecord(record(message: 'short'));

    expect(limited.message, 'short');
    expect(limited.data, isNull);
    expect(limited.error, isNull);
    expect(limited.stackTrace, isNull);
  });

  test('bounds the total number of structured entries', () {
    final limited = limitLogRecord(
      record(
        data: <String, Object?>{
          'items': <Object?>[for (var index = 0; index < 1000; index++) index],
        },
      ),
      maxEntries: 10,
    );

    final items = limited.data!['items']! as List<Object?>;
    expect(items.length, lessThanOrEqualTo(11));
    expect(items, contains(recordTruncationMarker));
  });

  test('bounds depth and survives cycles', () {
    final cyclic = <String, Object?>{};
    cyclic['self'] = cyclic;
    var deep = <String, Object?>{'leaf': 'value'};
    for (var index = 0; index < 20; index++) {
      deep = <String, Object?>{'next': deep};
    }

    final cycleLimited = limitLogRecord(
      record(data: cyclic),
      maxDepth: 2,
      maxEntries: 20,
    );
    expect(cycleLimited.data!['self'], recordTruncationMarker);

    final deepLimited = limitLogRecord(
      record(data: deep),
      maxDepth: 3,
      maxEntries: 200,
    );
    var node = deepLimited.data!;
    for (var index = 0; index < 3; index++) {
      node = node['next']! as Map<String, Object?>;
    }
    expect(node['next'], recordTruncationMarker);
  });

  test('a limited sink bounds the record and delegates flush', () async {
    final sink = _RecordingSink();
    final limited = LimitedSink(sink, maxTextLength: 32);

    await limited.write(record(message: 'x' * 500));
    await limited.flush();

    expect(sink.records.single.message.length, lessThanOrEqualTo(32));
    expect(sink.flushed, 1);
  });

  test(
    'the module caps a record even when redaction is disabled',
    () async {
      final registry = GetItRegistry();
      final module = LoggerModule(
        config: const LoggerConfig(
          activeSinks: <LogSinkKind>{LogSinkKind.memory},
          redactionEnabled: false,
          maxRecordTextLength: 64,
        ),
      );
      module.register(registry);

      final huge = 'x' * 500;
      registry.read<AppLogger>().info('contact andi@example.com $huge');
      final stored = registry.read<MemoryLogSink>().records.single.message;

      expect(stored.length, lessThanOrEqualTo(64));
      expect(stored, startsWith('contact andi@example.com'));
      await module.dispose();
    },
  );
}

final class _RecordingSink implements LogSink {
  final List<LogRecord> records = <LogRecord>[];
  int flushed = 0;

  @override
  FutureOr<void> write(LogRecord record) {
    records.add(record);
  }

  @override
  FutureOr<void> flush() {
    flushed++;
  }
}
