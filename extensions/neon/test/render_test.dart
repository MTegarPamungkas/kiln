import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('neon brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(
      project: const <String, Object?>{'name': 'neon_app'},
      answers: const <String, Object?>{
        'data_api_url': 'https://demo.aws.neon.tech/sql/rest',
        'api_key': 'demo-token',
        'schema': 'app',
      },
    );

    final paths = files.map((file) => file.relativePath).toList();
    expect(
      paths,
      containsAll(<String>[
        'lib/extensions/neon/neon_config.dart',
        'lib/extensions/neon/neon_gateway.dart',
        'lib/extensions/neon/neon_failure_mapper.dart',
        'lib/extensions/neon/neon_query_mapper.dart',
        'lib/extensions/neon/neon_remote_database.dart',
        'lib/extensions/neon/neon_support.dart',
        'lib/extensions/neon/neon_module.dart',
        'test/extensions/neon/test_support.dart',
        'test/extensions/neon/neon_contract_test.dart',
        'test/extensions/neon/neon_remote_database_test.dart',
        'test/extensions/neon/neon_query_mapper_test.dart',
        'test/extensions/neon/neon_config_test.dart',
        'test/extensions/neon/neon_failure_mapper_test.dart',
        'test/extensions/neon/neon_support_test.dart',
        'test/extensions/neon/neon_module_test.dart',
        'test/extensions/neon/neon_gateway_test.dart',
      ]),
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('neon_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains("dataApiUrl: 'https://demo.aws.neon.tech/sql/rest'"));
    expect(source, contains("apiKey: 'demo-token'"));
    expect(source, contains("schema: 'app'"));
    expect(source, isNot(contains('{{{')));
    expect(source, isNot(contains('&quot;')));

    final module = files.firstWhere(
      (file) => file.relativePath.endsWith('neon_module.dart'),
    );
    final moduleSource = String.fromCharCodes(module.bytes);
    expect(moduleSource, contains("'remote_database'"));
    expect(moduleSource, contains('NeonRemoteDatabase'));
  });
}
