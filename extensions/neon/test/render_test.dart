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
        'auth_url': 'https://demo.neonauth.test/neondb/auth',
        'schema': 'app',
        's3_endpoint': 'https://demo.storage.c-us-east-2.aws.neon.tech',
        's3_bucket': 'media',
        's3_region': 'us-east-2',
        's3_access_key_id': 'token-id',
        's3_secret_access_key': 's3-secret',
      },
    );

    final paths = files.map((file) => file.relativePath).toList();
    expect(
      paths,
      containsAll(<String>[
        'lib/extensions/neon/neon_config.dart',
        'lib/extensions/neon/neon_gateway.dart',
        'lib/extensions/neon/neon_auth_gateway.dart',
        'lib/extensions/neon/neon_auth_repository.dart',
        'lib/extensions/neon/neon_session_token_provider.dart',
        'lib/extensions/neon/neon_failure_mapper.dart',
        'lib/extensions/neon/neon_token_provider.dart',
        'lib/extensions/neon/neon_query_mapper.dart',
        'lib/extensions/neon/neon_remote_database.dart',
        'lib/extensions/neon/neon_support.dart',
        'lib/extensions/neon/neon_module.dart',
        'lib/extensions/neon/neon_s3_signer.dart',
        'lib/extensions/neon/neon_storage_config.dart',
        'lib/extensions/neon/neon_storage_gateway.dart',
        'lib/extensions/neon/neon_file_storage.dart',
        'test/extensions/neon/test_support.dart',
        'test/extensions/neon/neon_contract_test.dart',
        'test/extensions/neon/neon_remote_database_test.dart',
        'test/extensions/neon/neon_query_mapper_test.dart',
        'test/extensions/neon/neon_config_test.dart',
        'test/extensions/neon/neon_failure_mapper_test.dart',
        'test/extensions/neon/neon_support_test.dart',
        'test/extensions/neon/neon_module_test.dart',
        'test/extensions/neon/neon_auth_repository_test.dart',
        'test/extensions/neon/neon_gateway_test.dart',
        'test/extensions/neon/neon_token_provider_test.dart',
        'test/extensions/neon/neon_s3_signer_test.dart',
        'test/extensions/neon/neon_storage_config_test.dart',
        'test/extensions/neon/neon_storage_gateway_test.dart',
        'test/extensions/neon/neon_file_storage_test.dart',
      ]),
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('neon_config.dart'),
    );
    final configSource = String.fromCharCodes(config.bytes);
    expect(
      configSource,
      contains("dataApiUrl: 'https://demo.aws.neon.tech/sql/rest'"),
    );
    expect(configSource, contains("apiKey: 'demo-token'"));
    expect(configSource, contains("authUrl: 'https://demo.neonauth.test/neondb/auth'"));
    expect(configSource, contains("schema: 'app'"));
    expect(configSource, isNot(contains('{{{')));

    final storageConfig = files.firstWhere(
      (file) => file.relativePath.endsWith('neon_storage_config.dart'),
    );
    final storageSource = String.fromCharCodes(storageConfig.bytes);
    expect(
      storageSource,
      contains("endpoint: 'https://demo.storage.c-us-east-2.aws.neon.tech'"),
    );
    expect(storageSource, contains("bucket: 'media'"));
    expect(storageSource, contains("region: 'us-east-2'"));
    expect(storageSource, contains("accessKeyId: 'token-id'"));
    expect(storageSource, contains("secretAccessKey: 's3-secret'"));
    expect(storageSource, isNot(contains('&quot;')));

    final module = files.firstWhere(
      (file) => file.relativePath.endsWith('neon_module.dart'),
    );
    final moduleSource = String.fromCharCodes(module.bytes);
    expect(moduleSource, contains("'auth'"));
    expect(moduleSource, contains("'remote_database'"));
    expect(moduleSource, contains("'file_storage'"));
    expect(moduleSource, contains('NeonAuthRepository'));
    expect(moduleSource, contains('NeonRemoteDatabase'));
    expect(moduleSource, contains('NeonFileStorage'));
  });
}
