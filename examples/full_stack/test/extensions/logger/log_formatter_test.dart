import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/logger/log_formatter.dart';

void main() {
  const formatter = LogFormatter();
  final record = LogRecord(
    level: LogLevel.error,
    message: 'request failed',
    timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5, 6),
    error: StateError('boom'),
    data: const <String, Object?>{'url': '/users', 'attempt': 2},
  );

  test('formats a stable human-readable line', () {
    final line = formatter.format(record);

    expect(line, startsWith('2026-01-02T03:04:05.006Z [ERROR] request failed'));
    expect(line, contains('error: Bad state: boom'));
    expect(line, contains('"url":"/users"'));
    expect(line, contains('"attempt":2'));
    expect(LogFormatter.levelLabel(LogLevel.warning), 'WARNING');
  });

  test('formats one JSON object per line', () {
    final decoded =
        jsonDecode(formatter.formatJson(record)) as Map<String, Object?>;

    expect(decoded['timestamp'], '2026-01-02T03:04:05.006Z');
    expect(decoded['level'], 'error');
    expect(decoded['message'], 'request failed');
    expect(decoded['error'], contains('boom'));
    expect(decoded['data'], <String, Object?>{
      'url': '/users',
      'attempt': 2,
    });
    expect(formatter.formatJson(record), isNot(contains('\n')));
  });

  test('makes non-JSON data safe instead of throwing', () {
    final withDate = LogRecord(
      level: LogLevel.info,
      message: 'date',
      timestamp: DateTime.utc(2026, 1, 2),
      data: <String, Object?>{'at': DateTime.utc(2026, 1, 2, 3)},
    );

    final decoded =
        jsonDecode(formatter.formatJson(withDate)) as Map<String, Object?>;

    expect((decoded['data']! as Map<String, Object?>)['at'], contains('2026'));
  });
}
