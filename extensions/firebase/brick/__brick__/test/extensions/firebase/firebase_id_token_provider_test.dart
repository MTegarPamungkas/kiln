import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_id_token_provider.dart';

import 'firebase_contract_test.dart';

void main() {
  test('accessToken reads the current Firebase ID token', () async {
    final gateway = FakeFirebaseAuthGateway()..idTokenValue = 'current-token';
    final provider = FirebaseIdTokenProvider(gateway: gateway);

    expect(await provider.accessToken(), 'current-token');
    expect(gateway.tokenRefreshes, [false]);
  });

  test('forceRefresh is forwarded to getIdToken', () async {
    final gateway = FakeFirebaseAuthGateway();
    final provider = FirebaseIdTokenProvider(gateway: gateway);

    await provider.accessToken();
    await provider.accessToken(forceRefresh: true);

    expect(gateway.tokenRefreshes, [false, true]);
  });

  test('a signed-out user yields no token', () async {
    final gateway = FakeFirebaseAuthGateway()..idTokenValue = null;
    final provider = FirebaseIdTokenProvider(gateway: gateway);

    expect(await provider.accessToken(), isNull);
  });

  test('clear completes without touching the token cache', () async {
    final provider = FirebaseIdTokenProvider(
      gateway: FakeFirebaseAuthGateway(),
    );

    await provider.clear();
  });

  test('token errors are mapped to Failures', () async {
    final gateway = FakeFirebaseAuthGateway()
      ..error = FirebaseException(
        plugin: 'firebase_auth',
        code: 'requires-recent-login',
      );
    final provider = FirebaseIdTokenProvider(gateway: gateway);

    await expectLater(
      provider.accessToken(forceRefresh: true),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.authSessionExpired,
        ),
      ),
    );
  });
}
