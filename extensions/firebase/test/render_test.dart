import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('firebase brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'firebase_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/firebase/firebase_module.dart',
        'lib/extensions/firebase/firebase_app.dart',
        'lib/extensions/firebase/firebase_auth_repository.dart',
        'lib/extensions/firebase/firebase_gateway.dart',
        'lib/extensions/firebase/firebase_failure_mapper.dart',
        'lib/extensions/firebase/firebase_config.dart',
        'lib/extensions/firebase/firebase_emulator.dart',
        'lib/extensions/firebase/firebase_account_management.dart',
        'lib/extensions/firebase/firebase_id_token_provider.dart',
        'lib/extensions/firebase/firebase_session_bridge.dart',
        'lib/extensions/firebase/firestore_gateway.dart',
        'lib/extensions/firebase/firestore_remote_database.dart',
        'lib/extensions/firebase/firestore_query_mapper.dart',
        'lib/extensions/firebase/firebase_storage_gateway.dart',
        'lib/extensions/firebase/firebase_file_storage.dart',
        'test/extensions/firebase/firebase_auth_test.dart',
        'test/extensions/firebase/firebase_failure_mapper_test.dart',
        'test/extensions/firebase/firebase_module_test.dart',
        'test/extensions/firebase/firebase_config_test.dart',
        'test/extensions/firebase/firebase_emulator_test.dart',
        'test/extensions/firebase/firebase_account_management_test.dart',
        'test/extensions/firebase/firebase_id_token_provider_test.dart',
        'test/extensions/firebase/firebase_session_bridge_test.dart',
        'test/extensions/firebase/firestore_remote_database_test.dart',
        'test/extensions/firebase/firestore_query_mapper_test.dart',
        'test/extensions/firebase/firebase_file_storage_test.dart',
        'test/extensions/firebase/firebase_contract_test.dart',
      ]),
    );
    expect(
      files.map((file) => file.relativePath),
      isNot(contains('hooks/pre_gen.dart')),
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('firebase_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains('FirebaseOptionsSource.generated'));
    expect(source, contains("'lib/firebase_options.dart'"));
    expect(source, contains("'localhost'"));
    expect(source, contains('useEmulatorInDevelopment = true'));
  });
}
