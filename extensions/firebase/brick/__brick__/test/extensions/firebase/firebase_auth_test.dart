import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_auth_repository.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_gateway.dart';

import 'firebase_contract_test.dart';

void main() {
  group('FirebaseAuthRepository', () {
    test('signIn returns the gateway user as a session', () async {
      final gateway = FakeFirebaseAuthGateway();
      final repository = FirebaseAuthRepository(gateway: gateway);

      final session = await repository.signIn(
        email: 'user@kiln.dev',
        password: 'password123',
      );

      expect(session.userId, 'firebase-user');
      expect(session.email, 'user@kiln.dev');
      expect(repository.currentSession?.userId, session.userId);
      expect(gateway.calls, contains('signIn:user@kiln.dev'));
    });

    test('signUp keeps the display name from Firebase', () async {
      final gateway = FakeFirebaseAuthGateway();
      final repository = FirebaseAuthRepository(gateway: gateway);

      final session = await repository.signUp(
        email: 'new@kiln.dev',
        password: 'password123',
        displayName: 'New User',
      );

      expect(session.displayName, 'New User');
      expect(repository.currentSession?.displayName, 'New User');
    });

    test('authStateChanges mirrors Firebase auth state', () async {
      final gateway = FakeFirebaseAuthGateway();
      final repository = FirebaseAuthRepository(gateway: gateway);
      final emitted = <AuthSession?>[];
      final subscription = repository.authStateChanges.listen(emitted.add);

      gateway.emit(
        const FirebaseUser(uid: 'remote-user', email: 'remote@kiln.dev'),
      );
      gateway.emit(null);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.map((session) => session?.userId), ['remote-user', null]);
      await subscription.cancel();
    });

    test('invalid credentials become an authentication Failure', () async {
      final gateway = FakeFirebaseAuthGateway();
      final repository = FirebaseAuthRepository(gateway: gateway);

      await expectLater(
        repository.signIn(email: 'user@kiln.dev', password: 'nope'),
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
      expect(repository.currentSession, isNull);
    });

    test('signOut clears the session', () async {
      final gateway = FakeFirebaseAuthGateway();
      final repository = FirebaseAuthRepository(gateway: gateway);
      await repository.signIn(email: 'user@kiln.dev', password: 'password123');

      await repository.signOut();

      expect(repository.currentSession, isNull);
      expect(gateway.currentUser, isNull);
    });
  });

  group('FirebaseSocialAuth', () {
    test('signIn maps the provider credential to Firebase tokens', () async {
      final gateway = FakeFirebaseAuthGateway();
      final social = FirebaseSocialAuth(gateway: gateway);

      final credential = await social.signIn(SocialProvider.apple);

      expect(credential, isNotNull);
      expect(credential?.provider, SocialProvider.apple);
      expect(credential?.idToken, 'social-id-token');
      expect(credential?.accessToken, 'social-access-token');
      expect(credential?.email, 'social@kiln.dev');
      expect(gateway.calls, contains('provider:apple'));
    });

    test('signIn returns null when Firebase yields no credential', () async {
      final gateway = FakeFirebaseAuthGateway()..providerReturnsNull = true;
      final social = FirebaseSocialAuth(gateway: gateway);

      expect(await social.signIn(SocialProvider.google), isNull);
    });

    test('provider errors become auth Failures', () async {
      final gateway = FakeFirebaseAuthGateway()
        ..socialError = const Failure(
          code: FailureCode.authCancelled,
          message: 'Cancelled',
          kind: FailureKind.cancelled,
        );
      final social = FirebaseSocialAuth(gateway: gateway);

      await expectLater(
        social.signIn(SocialProvider.google),
        throwsA(
          isA<Failure>().having(
            (value) => value.code,
            'code',
            FailureCode.authCancelled,
          ),
        ),
      );
    });

    test('signOut delegates to Firebase', () async {
      final gateway = FakeFirebaseAuthGateway();
      final social = FirebaseSocialAuth(gateway: gateway);
      gateway.emit(const FirebaseUser(uid: 'signed-in'));

      await social.signOut();

      expect(gateway.currentUser, isNull);
      expect(gateway.calls, contains('signOut'));
    });
  });
}
