import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/http_retry/retry_after_parser.dart';

void main() {
  const parser = RetryAfterParser();
  final now = DateTime.utc(2026, 11, 1, 12);

  test('parses seconds', () {
    expect(parser.parse('5', now: now), const Duration(seconds: 5));
    expect(parser.parse('-3', now: now), Duration.zero);
  });

  test('parses an HTTP date', () {
    expect(
      parser.parse('Sun, 01 Nov 2026 12:00:10 GMT', now: now),
      const Duration(seconds: 10),
    );
  });

  test('returns zero for a past date and null for invalid input', () {
    expect(
      parser.parse('Sat, 31 Oct 2026 12:00:00 GMT', now: now),
      Duration.zero,
    );
    expect(parser.parse('not a date', now: now), isNull);
    expect(parser.parse(null, now: now), isNull);
  });
}
