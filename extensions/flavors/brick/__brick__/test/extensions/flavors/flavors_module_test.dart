import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/flavors/flavors_module.dart';
import 'package:{{app_name}}/extensions/flavors/flavors_support.dart';
import 'package:{{app_name}}/extensions/flavors/release_guard.dart';

void main() {
  test('module contributes the banner wrapper', () {
    final registry = GetItRegistry()
      ..registerSingleton<SlotRegistry>(SlotRegistry())
      ..registerSingleton<AppFlavor>(AppFlavor.development);

    const FlavorsModule().register(registry);

    expect(registry.read<ReleaseGuard>(), isA<ReleaseGuard>());
    expect(registry.read<FlavorsSupport>(), isA<FlavorsSupport>());
    expect(
      registry
          .read<SlotRegistry>()
          .open<AppWrapper>(SlotNames.appWrappers)
          .items,
      hasLength(1),
    );
  });
}
