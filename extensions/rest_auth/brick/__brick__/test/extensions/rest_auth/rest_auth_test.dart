import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';

import 'test_support.dart';

void main() {
  test('signIn stores tokens, user, and emits the session', () async {
    final harness = AuthHarness();
    final emitted = <AuthSession?>[];
    final subscription = harness.auth.authStateChanges.listen(emitted.add);

    final session = await harness.auth.signIn(
      email: 'user@kiln.dev',
      password: 'password123',
    );

    expect(session.userId, 'user-1');
    expect(session.email, 'user@kiln.dev');
    expect(session.displayName, 'Tegar');
    expect(harness.auth.currentSession, session);
    expect(emitted.last, session);
    expect(harness.storage.snapshot['rest_auth.access_token'], isNotEmpty);
    expect(
      harness.storage.snapshot['rest_auth.refresh_token'],
      'refresh-token',
    );
    expect(harness.storage.snapshot['rest_auth.user'], contains('user-1'));

    await subscription.cancel();
  });

  test('signIn rejects invalid credentials without touching storage', () async {
    final harness = AuthHarness();

    await expectLater(
      harness.auth.signIn(email: 'user@kiln.dev', password: 'wrong'),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.authInvalidCredentials,
        ),
      ),
    );

    expect(harness.auth.currentSession, isNull);
    expect(harness.storage.snapshot, isEmpty);
  });

  test('signUp uses the register endpoint and display name', () async {
    final harness = AuthHarness();

    final session = await harness.auth.signUp(
      email: 'new@kiln.dev',
      password: 'password123',
      displayName: 'New User',
    );

    expect(session.userId, 'user-2');
    expect(session.displayName, 'New User');
    expect(harness.client.requests.single.uri.path, '/auth/register');
  });

  test('initialize restores the stored session', () async {
    final harness = AuthHarness();
    await harness.auth.signIn(email: 'user@kiln.dev', password: 'password123');
    final restored = AuthHarness(storage: harness.storage);

    await restored.auth.initialize();

    expect(restored.auth.currentSession, isNotNull);
    expect(restored.auth.currentSession?.userId, 'user-1');
    expect(restored.auth.currentSession?.displayName, 'Tegar P');
  });

  test('signOut clears the session and the store', () async {
    final harness = AuthHarness();
    await harness.auth.signIn(email: 'user@kiln.dev', password: 'password123');
    final emitted = <AuthSession?>[];
    final subscription = harness.auth.authStateChanges.listen(emitted.add);

    await harness.auth.signOut();

    expect(harness.auth.currentSession, isNull);
    expect(emitted, contains(null));
    expect(harness.storage.snapshot, isEmpty);

    await subscription.cancel();
  });

  test('signOut still clears tokens when the server fails', () async {
    final harness = AuthHarness();
    await harness.auth.signIn(email: 'user@kiln.dev', password: 'password123');
    harness.client.failure = const Failure(
      code: FailureCode.networkOffline,
      message: 'offline',
      kind: FailureKind.network,
    );

    await harness.auth.signOut();

    expect(harness.auth.currentSession, isNull);
    expect(harness.storage.snapshot, isEmpty);
  });
}
