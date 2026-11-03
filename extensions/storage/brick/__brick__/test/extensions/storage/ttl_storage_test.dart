import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/storage/ttl_storage.dart';

import 'test_support.dart';

void main() {
  test('expires values using the injected Clock', () async {
    final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
    final storage = TtlStorage(
      inner: createTestStorage(),
      clock: clock,
      defaultTtl: const Duration(seconds: 10),
    );

    await storage.write('session', 'abc');
    expect(await storage.read('session'), 'abc');
    expect(await storage.containsKey('session'), isTrue);

    clock.advance(const Duration(seconds: 11));
    expect(await storage.read('session'), isNull);
    expect(await storage.containsKey('session'), isFalse);
  });

  test('supports a custom ttl per value', () async {
    final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
    final storage = TtlStorage(
      inner: createTestStorage(),
      clock: clock,
      defaultTtl: const Duration(hours: 1),
    );

    await storage.write('short', 'x', ttl: const Duration(seconds: 1));
    clock.advance(const Duration(seconds: 2));

    expect(await storage.read('short'), isNull);
    expect(await storage.keys(), isEmpty);
  });
}
