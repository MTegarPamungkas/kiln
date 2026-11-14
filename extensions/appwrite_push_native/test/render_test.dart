import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('appwrite_push_native brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'kiln_app'});
    final paths = files.map((file) => file.relativePath).toList();

    expect(
      paths,
      containsAll(<String>[
        'lib/extensions/appwrite_push_native/appwrite_push_native_config.dart',
        'lib/extensions/appwrite_push_native/appwrite_push_native_module.dart',
        'lib/extensions/appwrite_push_native/appwrite_push_native_transport.dart',
        'test/extensions/appwrite_push_native/appwrite_push_native_contract_test.dart',
        'test/extensions/appwrite_push_native/appwrite_push_native_e2e_test.dart',
        'test/extensions/appwrite_push_native/appwrite_push_native_envelope_test.dart',
        'test/extensions/appwrite_push_native/appwrite_push_native_module_test.dart',
        'test/extensions/appwrite_push_native/appwrite_push_native_transport_test.dart',
      ]),
    );
  });
}
