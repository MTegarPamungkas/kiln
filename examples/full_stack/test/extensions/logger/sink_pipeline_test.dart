import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/logger/log_sink.dart';
import 'package:full_stack/extensions/logger/memory_log_sink.dart';
import 'package:full_stack/extensions/logger/sink_pipeline.dart';

void main() {
  test('one failing sink does not stop the others', () async {
    final failures = <String>[];
    final memory = MemoryLogSink();
    final pipeline = SinkPipeline(
      <LogSink>[_ThrowingSink(), _ThrowingSink(asynchronous: true), memory],
      onFailure: (message, error, stackTrace) {
        failures.add('$message $error');
      },
    );

    pipeline.write(_record());
    await pipeline.flush();

    expect(memory.records, hasLength(1));
    expect(failures, hasLength(2));
    expect(
      failures.every((failure) => failure.contains('_ThrowingSink')),
      isTrue,
    );
    expect(failures.any((failure) => failure.contains('sync boom')), isTrue);
    expect(failures.any((failure) => failure.contains('async boom')), isTrue);
  });

  test('a disabled pipeline drops records', () async {
    final memory = MemoryLogSink();
    final pipeline = SinkPipeline(<LogSink>[memory], enabled: false);

    pipeline.write(_record());
    await pipeline.flush();

    expect(memory.records, isEmpty);
  });

  test('sinks can be added and removed at runtime', () async {
    final memory = MemoryLogSink();
    final pipeline = SinkPipeline(<LogSink>[]);

    pipeline.add(memory);
    pipeline.write(_record());
    expect(pipeline.remove(memory), isTrue);
    pipeline.write(_record());
    await pipeline.flush();

    expect(memory.records, hasLength(1));
    expect(pipeline.sinks, isEmpty);
  });
}

LogRecord _record() {
  return LogRecord(
    level: LogLevel.info,
    message: 'hello',
    timestamp: DateTime.utc(2026, 1, 1),
  );
}

final class _ThrowingSink implements LogSink {
  _ThrowingSink({this.asynchronous = false});

  final bool asynchronous;

  @override
  FutureOr<void> write(LogRecord record) {
    if (asynchronous) {
      return Future<void>.error(StateError('async boom'));
    }
    throw StateError('sync boom');
  }

  @override
  FutureOr<void> flush() => null;
}
