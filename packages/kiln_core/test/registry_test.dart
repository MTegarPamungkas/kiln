import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

final class _Thing {
  const _Thing(this.value);

  final int value;
}

void main() {
  group('GetItRegistry', () {
    late GetItRegistry registry;

    setUp(() {
      registry = GetItRegistry();
    });

    test('registers and reads a singleton', () {
      const value = 'kiln';
      registry.registerSingleton<String>(value);

      expect(registry.isRegistered<String>(), isTrue);
      expect(registry.read<String>(), value);
      expect(registry.readOrNull<String>(), value);
    });

    test('returns null for a missing optional registration', () {
      expect(registry.readOrNull<int>(), isNull);
      expect(registry.isRegistered<int>(), isFalse);
    });

    test('throws when reading a missing registration', () {
      expect(() => registry.read<int>(), throwsA(anything));
    });

    test('supports named registrations', () {
      registry.registerSingleton<int>(1, instanceName: 'one');
      registry.registerSingleton<int>(2, instanceName: 'two');

      expect(registry.read<int>(instanceName: 'one'), 1);
      expect(registry.read<int>(instanceName: 'two'), 2);
      expect(registry.readOrNull<int>(instanceName: 'three'), isNull);
    });

    test(
      'lazy singleton is created once and factories create new instances',
      () {
        var lazyCalls = 0;
        registry.registerLazySingleton<_Thing>(() {
          lazyCalls++;
          return const _Thing(1);
        });

        final first = registry.read<_Thing>();
        final second = registry.read<_Thing>();
        expect(identical(first, second), isTrue);
        expect(lazyCalls, 1);

        var factoryCalls = 0;
        registry.registerFactory<DateTime>(() {
          factoryCalls++;
          return DateTime.now();
        });
        registry.read<DateTime>();
        registry.read<DateTime>();
        expect(factoryCalls, 2);
      },
    );

    test('unregisters a service', () {
      registry.registerSingleton<String>('temporary');
      registry.unregister<String>();

      expect(registry.isRegistered<String>(), isFalse);
      expect(registry.readOrNull<String>(), isNull);
    });
  });
}
