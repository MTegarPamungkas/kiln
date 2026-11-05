import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/notifications/timezone_resolver.dart';
import 'package:timezone/timezone.dart' as tz;

final class _FakeTimezoneSource implements TimezoneSource {
  const _FakeTimezoneSource(this.identifier);

  final String? identifier;

  @override
  Future<String?> localIdentifier() async => identifier;
}

void main() {
  tearDown(() {
    tz.setLocalLocation(tz.UTC);
  });

  test('configures the device timezone and converts instants', () async {
    final resolver = TimezoneResolver(
      source: const _FakeTimezoneSource('Asia/Jakarta'),
    );

    expect(await resolver.configure(), isTrue);
    expect(tz.local.name, 'Asia/Jakarta');
    expect(resolver.toLocal(DateTime.utc(2026, 1, 1, 5)).hour, 12);
  });

  test('reports false when the device has no timezone', () async {
    final resolver = TimezoneResolver(
      source: const _FakeTimezoneSource(null),
    );

    expect(await resolver.configure(), isFalse);
  });

  test('reports false for an unknown timezone', () async {
    final resolver = TimezoneResolver(
      source: const _FakeTimezoneSource('Nowhere/Missing'),
    );

    expect(await resolver.configure(), isFalse);
  });
}
