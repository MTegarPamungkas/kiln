import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_account.dart';

import 'test_support.dart';

void main() {
  test('signIn stores the session and emits it', () async {
    final account = FakeAppwriteAccount();
    final controller = SessionController();
    final auth = createFakeAuth(account: account, controller: controller).auth;
    final emitted = <AuthSession?>[];
    final subscription = auth.authStateChanges.listen(emitted.add);

    final session = await auth.signIn(
      email: account.validEmail,
      password: account.validPassword,
    );

    expect(session.userId, 'user-1');
    expect(session.email, account.validEmail);
    expect(auth.currentSession?.userId, session.userId);
    expect(emitted.last?.userId, session.userId);
    expect(controller.status, SessionStatus.authenticated);

    await subscription.cancel();
  });

  test('signIn rejects wrong credentials with an auth failure', () async {
    final auth = createFakeAuth().auth;

    await expectLater(
      auth.signIn(email: 'user@kiln.dev', password: 'wrong-password'),
      throwsA(
        isA<Failure>()
            .having(
              (failure) => failure.code,
              'code',
              FailureCode.authInvalidCredentials,
            )
            .having(
              (failure) => failure.kind,
              'kind',
              FailureKind.authentication,
            ),
      ),
    );
    expect(auth.currentSession, isNull);
  });

  test('signUp creates the account and signs it in', () async {
    final auth = createFakeAuth().auth;

    final session = await auth.signUp(
      email: 'new@kiln.dev',
      password: 'password123',
      displayName: 'New User',
    );

    expect(session.userId, isNotEmpty);
    expect(session.displayName, 'New User');
    expect(auth.currentSession, isNotNull);
  });

  test('signOut clears the session and emits null', () async {
    final auth = createFakeAuth().auth;
    await auth.signIn(email: 'user@kiln.dev', password: 'password123');
    final emitted = <AuthSession?>[];
    final subscription = auth.authStateChanges.listen(emitted.add);

    await auth.signOut();

    expect(auth.currentSession, isNull);
    expect(emitted, contains(null));
    await subscription.cancel();
  });

  test('restoreSession adopts a session that is still valid', () async {
    final account = FakeAppwriteAccount();
    account.setCurrent(
      const AppwriteAccountUser(
        id: 'user-1',
        email: 'user@kiln.dev',
        name: 'Kiln User',
        emailVerified: true,
      ),
    );
    final auth = createFakeAuth(account: account).auth;

    await auth.restoreSession();

    expect(auth.currentSession?.userId, 'user-1');
    expect(auth.currentSession?.displayName, 'Kiln User');
  });

  test('restoreSession clears the session when Appwrite rejects it', () async {
    final account = FakeAppwriteAccount()
      ..failure = appwriteUnauthorizedFailure();
    final auth = createFakeAuth(account: account).auth;

    await auth.restoreSession();

    expect(auth.currentSession, isNull);
  });
}
