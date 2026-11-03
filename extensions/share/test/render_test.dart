import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('share brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'share_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/share/share_module.dart',
        'lib/extensions/share/share_support.dart',
        'lib/extensions/share/share_gateway.dart',
        'lib/extensions/share/sdk_share_gateway.dart',
        'lib/extensions/share/device_share_service.dart',
        'test/extensions/share/share_test.dart',
      ]),
    );
  });
}
