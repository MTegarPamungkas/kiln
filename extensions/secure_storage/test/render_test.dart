import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('secure_storage brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'safe_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/secure_storage/secure_storage_module.dart',
        'lib/extensions/secure_storage/keystore_secure_storage.dart',
        'lib/extensions/secure_storage/secure_storage_gateway.dart',
        'lib/extensions/secure_storage/secure_token_store.dart',
        'lib/extensions/secure_storage/first_run_wipe.dart',
        'lib/extensions/secure_storage/secure_storage_health_check.dart',
      ]),
    );
    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('secure_storage_config.dart'),
    );
    expect(String.fromCharCodes(config.bytes), contains('safe_app.'));
  });
}
