import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_auth_repository.dart';

import 'test_support.dart';

void main() {
  test('signIn publishes the session on the controller', () async {
    final controller = SessionController();
    final auth = NeonAuthRepository(
      gateway: FakeNeonAuthGateway(),
      controller: controller,
    );

    final session = await auth.signIn(
      email: 'user@kiln.dev',
      password: 'password123',
    );

    expect(session.userId, 'user-1');
    expect(auth.currentSession?.userId, 'user-1');
    expect(controller.isAuthenticated, isTrue);
  });

  test('a failed signIn leaves the controller signed out', () async {
    final controller = SessionController();
    final auth = NeonAuthRepository(
      gateway: FakeNeonAuthGateway(),
      controller: controller,
    );

    await expectLater(
      auth.signIn(email: 'user@kiln.dev', password: 'wrong-password'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.authInvalidCredentials,
        ),
      ),
    );
    expect(auth.currentSession, isNull);
  });

  test('signOut clears the session', () async {
    final controller = SessionController();
    final auth = NeonAuthRepository(
      gateway: FakeNeonAuthGateway(),
      controller: controller,
    );
    await auth.signIn(email: 'user@kiln.dev', password: 'password123');

    await auth.signOut();

    expect(auth.currentSession, isNull);
    expect(controller.isAuthenticated, isFalse);
  });

  test('restore marks the controller unauthenticated when there is no session',
      () async {
    final controller = SessionController();
    final auth = NeonAuthRepository(
      gateway: FakeNeonAuthGateway(),
      controller: controller,
    );

    await auth.restore();

    expect(controller.status, SessionStatus.unauthenticated);
  });
}
