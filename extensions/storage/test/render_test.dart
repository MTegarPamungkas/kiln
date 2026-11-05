import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('storage brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'storage_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/storage/storage_module.dart',
        'lib/extensions/storage/shared_preferences_storage.dart',
        'lib/extensions/storage/storage_gateway.dart',
        'lib/extensions/storage/typed_key.dart',
        'lib/extensions/storage/ttl_storage.dart',
        'lib/extensions/storage/storage_migrator.dart',
      ]),
    );
    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('storage_config.dart'),
    );
    expect(String.fromCharCodes(config.bytes), contains('storage_app.'));
  });
}
