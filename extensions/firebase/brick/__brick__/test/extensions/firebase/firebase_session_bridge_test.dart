import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_gateway.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_session_bridge.dart';

import 'firebase_contract_test.dart';

void main() {
  test('auth changes update the SessionController', () async {
    final controller = SessionController();
    final gateway = FakeFirebaseAuthGateway();
    final bridge = FirebaseSessionBridge(
      controller: controller,
      users: () => gateway.authStateChanges,
    );

    bridge.start();
    gateway.emit(
      const FirebaseUser(
        uid: 'user-1',
        email: 'user@kiln.dev',
        displayName: 'User',
        emailVerified: true,
      ),
    );

    expect(controller.status, SessionStatus.authenticated);
    expect(controller.session?.userId, 'user-1');
    expect(controller.session?.displayName, 'User');
    expect(controller.session?.metadata['emailVerified'], isTrue);

    gateway.emit(null);
    expect(controller.status, SessionStatus.unauthenticated);
    expect(controller.session, isNull);

    await bridge.dispose();
    await controller.dispose();
  });

  test('start is idempotent and dispose cancels the subscription', () async {
    final controller = SessionController();
    final gateway = FakeFirebaseAuthGateway();
    final bridge = FirebaseSessionBridge(
      controller: controller,
      users: () => gateway.authStateChanges,
    );

    bridge.start();
    bridge.start();
    expect(bridge.isRunning, isTrue);

    await bridge.dispose();
    expect(bridge.isRunning, isFalse);

    gateway.emit(const FirebaseUser(uid: 'after-dispose'));
    expect(controller.session, isNull);

    await controller.dispose();
  });

  test('custom session mapping is honoured', () async {
    final controller = SessionController();
    final gateway = FakeFirebaseAuthGateway();
    final bridge = FirebaseSessionBridge(
      controller: controller,
      users: () => gateway.authStateChanges,
      toSession: (user) =>
          user == null ? null : AuthSession(userId: 'mapped-${user.uid}'),
    );

    bridge.start();
    gateway.emit(const FirebaseUser(uid: 'user-9'));

    expect(controller.session?.userId, 'mapped-user-9');

    await bridge.dispose();
    await controller.dispose();
  });
}
