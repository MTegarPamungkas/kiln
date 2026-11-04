import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/core/riverpod/kiln_providers.dart';
import 'package:{{app_name}}/core/riverpod/provider_overrides.dart';

void main() {
  test('kilnProvider reads the overridden Registry', () {
    final registry = createTestRegistry();
    final container = testProviderContainer(registry);
    addTearDown(container.dispose);

    expect(container.read(kilnProvider<Storage>()), isA<InMemoryStorage>());
    expect(container.read(registryProvider), same(registry));
  });

  test('kilnProvider returns a stable provider per type', () {
    // Riverpod keys providers by object identity, so inline
    // `ref.watch(kilnProvider<T>())` must reuse one instance per contract.
    expect(kilnProvider<Storage>(), same(kilnProvider<Storage>()));
    expect(kilnProvider<AppLogger>(), isNot(same(kilnProvider<Storage>())));
  });
}
