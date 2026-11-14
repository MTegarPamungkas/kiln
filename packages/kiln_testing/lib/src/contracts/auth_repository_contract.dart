import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef AuthRepositoryContractFactory = FutureOr<AuthRepository> Function();

/// Behavior every [AuthRepository] implementation must share.
void authRepositoryContract({
  required AuthRepositoryContractFactory create,
  String description = 'AuthRepository',
  String validEmail = 'user@kiln.dev',
  String validPassword = 'password123',
  String invalidPassword = 'wrong-password',

  /// Address the signUp test registers. Backends that reject duplicate emails
  /// need a fresh value per run; the default keeps the suite hermetic.
  String signUpEmail = 'new@kiln.dev',
}) {
  group('$description contract', () {
    test('starts signed out', () async {
      final auth = await create();

      expect(auth.currentSession, isNull);
    });

    test('signIn with valid credentials returns and emits a session', () async {
      final auth = await create();
      final emitted = <AuthSession?>[];
      final subscription = auth.authStateChanges.listen(emitted.add);

      final session = await auth.signIn(
        email: validEmail,
        password: validPassword,
      );

      expect(session.userId, isNotEmpty);
      expect(auth.currentSession, isNotNull);
      expect(emitted, isNotEmpty);
      expect(emitted.last?.userId, session.userId);

      await subscription.cancel();
    });

    test('signIn with invalid credentials throws an auth Failure', () async {
      final auth = await create();

      await expectLater(
        auth.signIn(email: validEmail, password: invalidPassword),
        throwsA(
          isA<Failure>()
              .having((value) => value.kind, 'kind', FailureKind.authentication)
              .having(
                (value) => value.code,
                'code',
                FailureCode.authInvalidCredentials,
              ),
        ),
      );
      expect(auth.currentSession, isNull);
    });

    test('signUp returns the created session with the display name', () async {
      final auth = await create();

      final session = await auth.signUp(
        email: signUpEmail,
        password: 'password123',
        displayName: 'New User',
      );

      expect(session.userId, isNotEmpty);
      expect(session.displayName, 'New User');
      expect(auth.currentSession, isNotNull);
    });

    test('signOut clears the session and emits null', () async {
      final auth = await create();
      await auth.signIn(email: validEmail, password: validPassword);
      final emitted = <AuthSession?>[];
      final subscription = auth.authStateChanges.listen(emitted.add);

      await auth.signOut();

      expect(auth.currentSession, isNull);
      expect(emitted, contains(null));

      await subscription.cancel();
    });
  });
}
