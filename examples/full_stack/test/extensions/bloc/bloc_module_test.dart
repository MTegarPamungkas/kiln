import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/app/app_wrappers.dart';
import 'package:full_stack/extensions/bloc/bloc_module.dart';
import 'package:full_stack/extensions/bloc/bloc_support.dart';

void main() {
  test('module registers the app wrapper', () {
    final registry = createTestRegistry();

    const BlocModule().register(registry);

    final slot = registry.read<SlotRegistry>().find<AppWrapper>(
      SlotNames.appWrappers,
    );
    expect(slot, isNotNull);
    expect(slot!.items, hasLength(1));
    expect(registry.read<BlocSupport>(), isA<BlocSupport>());
  });
}
