import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('appwrite brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'kiln_app'});
    final paths = files.map((file) => file.relativePath).toList();

    expect(
      paths,
      containsAll(<String>[
        'lib/extensions/appwrite/appwrite_module.dart',
        'lib/extensions/appwrite/appwrite_auth.dart',
        'lib/extensions/appwrite/appwrite_account.dart',
        'lib/extensions/appwrite/appwrite_config.dart',
        'lib/extensions/appwrite/appwrite_client_factory.dart',
        'lib/extensions/appwrite/appwrite_failure_mapper.dart',
        'lib/extensions/appwrite/appwrite_account_management.dart',
        'lib/extensions/appwrite/appwrite_session_bridge.dart',
        'lib/extensions/appwrite/appwrite_database_gateway.dart',
        'lib/extensions/appwrite/appwrite_remote_database.dart',
        'lib/extensions/appwrite/appwrite_query_mapper.dart',
        'lib/extensions/appwrite/appwrite_realtime_gateway.dart',
        'lib/extensions/appwrite/appwrite_storage_gateway.dart',
        'lib/extensions/appwrite/appwrite_file_storage.dart',
        'lib/extensions/appwrite/appwrite_functions.dart',
        'lib/extensions/appwrite/appwrite_push_targets.dart',
        'test/extensions/appwrite/appwrite_auth_test.dart',
        'test/extensions/appwrite/appwrite_functions_test.dart',
        'test/extensions/appwrite/appwrite_push_targets_test.dart',
        'test/extensions/appwrite/appwrite_module_test.dart',
        'test/extensions/appwrite/appwrite_config_test.dart',
        'test/extensions/appwrite/appwrite_failure_mapper_test.dart',
        'test/extensions/appwrite/appwrite_account_management_test.dart',
        'test/extensions/appwrite/appwrite_session_bridge_test.dart',
        'test/extensions/appwrite/appwrite_remote_database_test.dart',
        'test/extensions/appwrite/appwrite_query_mapper_test.dart',
        'test/extensions/appwrite/appwrite_realtime_gateway_test.dart',
        'test/extensions/appwrite/appwrite_file_storage_test.dart',
        'test/extensions/appwrite/appwrite_contract_test.dart',
        'test/extensions/appwrite/test_support.dart',
      ]),
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('appwrite_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains("projectId: 'kiln_demo'"));
    expect(source, contains("databaseId: 'kiln'"));
    expect(source, contains("bucketId: 'kiln_files'"));

    final golden = File(
      p.join(
        Directory.current.path,
        'test',
        'goldens',
        'rendered',
        'lib',
        'extensions',
        'appwrite',
        'appwrite_config.dart.golden',
      ),
    );
    if (Platform.environment['UPDATE_GOLDENS'] == '1') {
      await golden.parent.create(recursive: true);
      await golden.writeAsString(source);
    }
    expect(source, golden.readAsStringSync());
  });
}
