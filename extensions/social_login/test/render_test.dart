import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('social_login brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'social_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/social_login/social_login_module.dart',
        'lib/extensions/social_login/social_login.dart',
        'lib/extensions/social_login/social_credentials.dart',
        'lib/extensions/social_login/social_login_config.dart',
        'lib/extensions/social_login/social_login_failure_mapper.dart',
        'lib/extensions/social_login/nonce_generator.dart',
        'lib/extensions/social_login/social_availability.dart',
        'lib/extensions/social_login/google_credential_gateway.dart',
        'lib/extensions/social_login/apple_credential_gateway.dart',
        'lib/extensions/social_login/social_sign_out_listener.dart',
        'lib/extensions/social_login/gate_social_login.dart',
        'test/extensions/social_login/social_auth_contract_test.dart',
        'test/extensions/social_login/gate_social_login_test.dart',
      ]),
    );
  });
}
