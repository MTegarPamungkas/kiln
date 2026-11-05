import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_account_management.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_gateway.dart';

import 'firebase_contract_test.dart';

void main() {
  test('reports the verified state of the current user', () {
    final gateway = FakeFirebaseAuthGateway()..emailVerified = true;
    gateway.emit(const FirebaseUser(uid: 'user-1', emailVerified: true));
    final account = FirebaseAccountManagement(gateway: gateway);

    expect(account.isEmailVerified, isTrue);
  });

  test('isEmailVerified is false without a signed-in user', () {
    final account = FirebaseAccountManagement(
      gateway: FakeFirebaseAuthGateway(),
    );

    expect(account.isEmailVerified, isFalse);
  });

  test('sends a password reset message for the email', () async {
    final gateway = FakeFirebaseAuthGateway();
    final account = FirebaseAccountManagement(gateway: gateway);

    await account.sendPasswordResetEmail('user@kiln.dev');

    expect(gateway.calls, contains('reset:user@kiln.dev'));
  });

  test('sends a verification email and reloads the user', () async {
    final gateway = FakeFirebaseAuthGateway();
    final account = FirebaseAccountManagement(gateway: gateway);

    await account.sendEmailVerification();
    await account.reloadUser();

    expect(gateway.calls, contains('sendEmailVerification'));
    expect(gateway.calls, contains('reloadUser'));
  });

  test('updates display name and photo URL', () async {
    final gateway = FakeFirebaseAuthGateway();
    gateway.emit(const FirebaseUser(uid: 'user-1', displayName: 'Old'));
    final account = FirebaseAccountManagement(gateway: gateway);

    await account.updateDisplayName('New Name');
    await account.updatePhotoUrl('https://cdn.kiln.dev/avatar.png');

    expect(gateway.calls, contains('displayName:New Name'));
    expect(gateway.calls, contains('photoUrl:https://cdn.kiln.dev/avatar.png'));

    await account.updatePhotoUrl(null);
    expect(gateway.calls, contains('photoUrl:null'));
  });

  test('maps failures from every account action', () async {
    final gateway = FakeFirebaseAuthGateway()
      ..error = FirebaseException(
        plugin: 'firebase_auth',
        code: 'requires-recent-login',
      );
    final account = FirebaseAccountManagement(gateway: gateway);

    await expectLater(
      account.updateDisplayName('Nope'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.authSessionExpired,
        ),
      ),
    );
    await expectLater(
      account.sendPasswordResetEmail('user@kiln.dev'),
      throwsA(isA<Failure>()),
    );
    await expectLater(account.sendEmailVerification(), throwsA(isA<Failure>()));
    await expectLater(account.reloadUser(), throwsA(isA<Failure>()));
    await expectLater(account.updatePhotoUrl(null), throwsA(isA<Failure>()));
  });
}
