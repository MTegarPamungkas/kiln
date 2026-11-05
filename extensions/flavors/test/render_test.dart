import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('flavors brick renders entry points and launch configs', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'flavor_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        '.vscode/launch.json',
        'lib/main_development.dart',
        'lib/main_staging.dart',
        'lib/main_production.dart',
        'lib/extensions/flavors/app_flavors.dart',
        'lib/extensions/flavors/flavors_module.dart',
        'lib/extensions/flavors/release_guard.dart',
        'lib/extensions/flavors/flavor_x.dart',
        'test/extensions/flavors/launch_config_test.dart',
      ]),
    );
    final launch = files.firstWhere(
      (file) => file.relativePath.endsWith('launch.json'),
    );
    expect(String.fromCharCodes(launch.bytes), contains('main_development'));
  });
}
