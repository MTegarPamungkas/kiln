import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/logger/log_sink.dart';
import 'package:full_stack/extensions/logger/redacting_sink.dart';

void main() {
  test('redacts the message, data, and error text', () {
    final sink = _RecordingSink();
    final redacting = RedactingSink(sink);
    const jwt =
        'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0In0.signature';

    redacting.write(
      LogRecord(
        level: LogLevel.info,
        message: 'login andi@example.com Bearer abc.def',
        timestamp: DateTime.utc(2026, 1, 1),
        error: StateError('refresh with $jwt failed'),
        data: const <String, Object?>{
          'password': 'hunter2',
          'email': 'andi@example.com',
          'note': 'kept',
        },
      ),
    );

    final record = sink.records.single;
    expect(record.message, isNot(contains('andi@example.com')));
    expect(record.message, contains('[redacted]'));
    expect(record.message, isNot(contains('abc.def')));
    expect('${record.error}', isNot(contains('eyJ')));
    expect(record.data?['password'], '[redacted]');
    expect(record.data?['email'], '[redacted]');
    expect(record.data?['note'], 'kept');
    expect(record.timestamp, DateTime.utc(2026, 1, 1));
  });

  test('flush reaches the decorated sink', () async {
    final sink = _RecordingSink();
    final redacting = RedactingSink(sink);

    await redacting.flush();

    expect(sink.flushed, isTrue);
  });
}

final class _RecordingSink implements LogSink {
  final List<LogRecord> records = <LogRecord>[];
  bool flushed = false;

  @override
  FutureOr<void> write(LogRecord record) {
    records.add(record);
    return null;
  }

  @override
  FutureOr<void> flush() {
    flushed = true;
    return null;
  }
}
