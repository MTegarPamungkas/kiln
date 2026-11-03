import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/logger/memory_log_sink.dart';

void main() {
  test('keeps only the newest N records', () async {
    final sink = MemoryLogSink(capacity: 3);

    for (var index = 0; index < 5; index++) {
      sink.write(_record('entry $index'));
    }

    expect(sink.records.map((record) => record.message), <String>[
      'entry 2',
      'entry 3',
      'entry 4',
    ]);
    expect(sink.length, 3);
    expect(sink.isNotEmpty, isTrue);
  });

  test('clear empties the buffer', () async {
    final sink = MemoryLogSink(capacity: 2)..write(_record('one'));

    sink.clear();

    expect(sink.records, isEmpty);
    expect(sink.isEmpty, isTrue);
  });
}

LogRecord _record(String message) {
  return LogRecord(
    level: LogLevel.info,
    message: message,
    timestamp: DateTime.utc(2026, 1, 1),
  );
}
