import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/go_router/session_refresh_listenable.dart';

void main() {
  test('notifies when the session changes', () async {
    final session = SessionController(
      initialStatus: SessionStatus.authenticated,
    );
    final listenable = SessionRefreshListenable(session);
    var notifications = 0;
    listenable.addListener(() => notifications++);

    session.markUnauthenticated();
    expect(notifications, 1);

    session.setSession(const AuthSession(userId: 'user-1'));
    expect(notifications, 2);

    listenable.dispose();
    session.markUnauthenticated();
    expect(notifications, 2);

    await session.dispose();
  });

  test('can be disposed more than once', () async {
    final session = SessionController();
    final listenable = SessionRefreshListenable(session);

    listenable.dispose();
    listenable.dispose();

    await session.dispose();
  });
}
