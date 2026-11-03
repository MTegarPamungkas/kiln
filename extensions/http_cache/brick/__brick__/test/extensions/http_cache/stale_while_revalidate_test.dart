import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/http_cache/cache_control_parser.dart';
import 'package:{{app_name}}/extensions/http_cache/stale_while_revalidate.dart';

void main() {
  const checker = StaleWhileRevalidate();

  test('serves a stale entry within the stale window', () {
    final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
    final entry = CacheEntry(
      response: const HttpResponse(statusCode: 200),
      storedAt: clock.now(),
      ttl: const Duration(seconds: 10),
    );
    const control = CacheControl(
      staleWhileRevalidate: Duration(seconds: 30),
    );

    clock.advance(const Duration(seconds: 15));
    expect(
      checker.canServe(
        entry: entry,
        control: control,
        clock: clock,
        enabled: true,
      ),
      isTrue,
    );

    clock.advance(const Duration(seconds: 30));
    expect(
      checker.canServe(
        entry: entry,
        control: control,
        clock: clock,
        enabled: true,
      ),
      isFalse,
    );
    expect(
      checker.canServe(
        entry: entry,
        control: control,
        clock: clock,
        enabled: false,
      ),
      isFalse,
    );
  });
}
