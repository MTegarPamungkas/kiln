import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/http_cache/cache_control_parser.dart';

void main() {
  const parser = CacheControlParser();

  test('parses flags and durations', () {
    final control = parser.parse(
      'no-store, no-cache, must-revalidate, immutable, '
      'max-age=60, stale-while-revalidate=30',
    );

    expect(control.noStore, isTrue);
    expect(control.noCache, isTrue);
    expect(control.mustRevalidate, isTrue);
    expect(control.immutable, isTrue);
    expect(control.maxAge, const Duration(seconds: 60));
    expect(control.staleWhileRevalidate, const Duration(seconds: 30));
  });

  test('returns defaults for missing or invalid input', () {
    final control = parser.parse(null);

    expect(control.noStore, isFalse);
    expect(control.maxAge, isNull);
    expect(parser.parse('max-age=bad').maxAge, isNull);
  });
}
