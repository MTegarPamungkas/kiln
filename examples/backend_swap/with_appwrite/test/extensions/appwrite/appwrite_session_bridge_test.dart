import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_account.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_session_bridge.dart';

import 'test_support.dart';

void main() {
  test('establish fills SessionController and emits the session', () async {
    final account = FakeAppwriteAccount()
      ..setCurrent(
        const AppwriteAccountUser(id: 'user-1', email: 'user@kiln.dev'),
      );
    final controller = SessionController();
    final bridge = AppwriteSessionBridge(
      controller: controller,
      tokenProvider: AppwriteTokenProvider(account: account),
    );
    final emitted = <AuthSession?>[];
    final subscription = bridge.changes.listen(emitted.add);

    final session = bridge.establish(
      user: const AppwriteAccountUser(
        id: 'user-1',
        email: 'user@kiln.dev',
        name: 'Kiln User',
      ),
      session: AppwriteAccountSession(
        id: 'session-1',
        userId: 'user-1',
        expiresAt: DateTime.utc(2030),
      ),
    );

    expect(controller.status, SessionStatus.authenticated);
    expect(controller.session?.userId, 'user-1');
    expect(session.displayName, 'Kiln User');
    expect(session.expiresAt, DateTime.utc(2030));
    expect(session.metadata['appwriteSessionId'], 'session-1');
    expect(emitted.last?.userId, 'user-1');
    await subscription.cancel();
  });

  test('listeners receive every emitted session', () async {
    final bridge = AppwriteSessionBridge();
    final emitted = <AuthSession?>[];
    final subscription = bridge.changes.listen(emitted.add);

    bridge.establish(
      user: const AppwriteAccountUser(id: 'user-1', email: 'user@kiln.dev'),
    );

    expect(emitted.last?.userId, 'user-1');
    await subscription.cancel();
  });

  test('token provider mints a JWT and clear drops it', () async {
    final account = FakeAppwriteAccount()
      ..setCurrent(
        const AppwriteAccountUser(id: 'user-1', email: 'user@kiln.dev'),
      );
    final tokens = AppwriteTokenProvider(account: account);
    final bridge = AppwriteSessionBridge(
      controller: SessionController(),
      tokenProvider: tokens,
    );

    bridge.establish(
      user: const AppwriteAccountUser(id: 'user-1', email: 'user@kiln.dev'),
    );

    expect(await tokens.accessToken(), 'jwt-user-1');
    expect(await tokens.accessToken(), 'jwt-user-1');
    expect(account.createJwtCalls, 1);

    account.setCurrent(null);
    bridge.clear();
    expect(await tokens.accessToken(), isNull);
  });

  test('clear marks the controller unauthenticated', () async {
    final controller = SessionController();
    final bridge = AppwriteSessionBridge(controller: controller);
    bridge.establish(
      user: const AppwriteAccountUser(id: 'user-1', email: 'user@kiln.dev'),
    );
    final emitted = <AuthSession?>[];
    final subscription = bridge.changes.listen(emitted.add);

    bridge.clear();

    expect(controller.status, SessionStatus.unauthenticated);
    expect(controller.session, isNull);
    expect(emitted.last, isNull);
    await subscription.cancel();
  });
}
