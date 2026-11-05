import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/rest_auth/rest_account_management.dart';
import 'package:full_stack/extensions/rest_auth/rest_auth_config.dart';

import 'test_support.dart';

void main() {
  test('sends reset and verification requests', () async {
    final harness = AuthHarness();
    await harness.auth.signIn(email: 'user@kiln.dev', password: 'password123');
    final account = RestAccountManagement(
      auth: harness.auth,
      config: testConfig,
    );

    await account.sendPasswordResetEmail('user@kiln.dev');
    await account.sendEmailVerification();

    final paths = harness.client.requests.map((request) => request.uri.path);
    expect(paths, contains('/auth/forgot-password'));
    expect(paths, contains('/auth/verify-email'));
    expect(account.isEmailVerified, isTrue);
  });

  test('updates the profile and reloads the user', () async {
    final harness = AuthHarness();
    await harness.auth.signIn(email: 'user@kiln.dev', password: 'password123');
    final account = RestAccountManagement(
      auth: harness.auth,
      config: testConfig,
    );

    await account.updateDisplayName('Tegar P');
    await account.updatePhotoUrl('https://cdn.kiln.dev/a.png');
    await account.reloadUser();

    final patches = harness.client.requests.where(
      (request) => request.method == HttpMethod.patch,
    );
    expect(patches, hasLength(2));
  });

  test('reports missing optional endpoints', () async {
    final harness = AuthHarness();
    final account = RestAccountManagement(
      auth: harness.auth,
      config: const RestAuthConfig(baseUrl: 'https://api.kiln.dev'),
    );

    await expectLater(
      account.sendPasswordResetEmail('user@kiln.dev'),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.configurationMissing,
        ),
      ),
    );
  });
}
