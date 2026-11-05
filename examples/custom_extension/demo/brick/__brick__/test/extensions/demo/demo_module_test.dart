import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import '../../../lib/extensions/demo/demo_config.dart';
import '../../../lib/extensions/demo/demo_module.dart';

void main() {
  test('module registers its config', () {
    final registry = createTestRegistry();

    const DemoModule().register(registry);

    expect(registry.read<DemoConfig>(), isNotNull);
  });
}
