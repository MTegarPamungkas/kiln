import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('rest_auth brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(
      project: const {'name': 'auth_app'},
      answers: const {'base_url': 'https://api.example.com'},
    );

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/rest_auth/rest_auth_module.dart',
        'lib/extensions/rest_auth/rest_auth.dart',
        'lib/extensions/rest_auth/rest_auth_config.dart',
        'lib/extensions/rest_auth/rest_auth_failure_mapper.dart',
        'lib/extensions/rest_auth/rest_token_store.dart',
        'lib/extensions/rest_auth/token_refresher.dart',
        'lib/extensions/rest_auth/jwt_expiry.dart',
        'lib/extensions/rest_auth/auth_response_parser.dart',
        'lib/extensions/rest_auth/auth_middleware.dart',
        'lib/extensions/rest_auth/unauthorized_handler.dart',
        'lib/extensions/rest_auth/rest_account_management.dart',
        'lib/extensions/rest_auth/rest_session_bridge.dart',
        'test/extensions/rest_auth/rest_auth_contract_test.dart',
      ]),
    );
    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('rest_auth_config.dart'),
    );
    expect(
      String.fromCharCodes(config.bytes),
      contains("loginPath: '/auth/login'"),
    );
  });
}
