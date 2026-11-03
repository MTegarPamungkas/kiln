import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('BrickRenderer', () {
    test('renders template variables into paths and contents', () async {
      final files = await const BrickRenderer().render(
        bundle: bundleFromFixture('tiny_brick'),
        vars: const {'id': 'demo', 'name': 'Demo Extension'},
      );

      expect(files.map((file) => file.relativePath), [
        'lib/extensions/demo/demo_module.dart',
        'test/extensions/demo/demo_module_test.dart',
      ]);
      final module = files.firstWhere(
        (file) => file.relativePath.endsWith('demo_module.dart'),
      );
      expect(String.fromCharCodes(module.bytes), contains('Demo Extension'));
    });

    test('renders a fresh directory each time', () async {
      final first = await const BrickRenderer().render(
        bundle: bundleFromFixture('tiny_brick'),
        vars: const {'id': 'one', 'name': 'One'},
      );
      final second = await const BrickRenderer().render(
        bundle: bundleFromFixture('tiny_brick'),
        vars: const {'id': 'two', 'name': 'Two'},
      );

      expect(first.first.relativePath, contains('one'));
      expect(second.first.relativePath, contains('two'));
    });
  });
}
