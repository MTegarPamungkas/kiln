import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  group('SessionController', () {
    test('starts unknown with no session', () {
      final controller = SessionController();

      expect(controller.status, SessionStatus.unknown);
      expect(controller.session, isNull);
      expect(controller.isAuthenticated, isFalse);
    });

    test('transitions to authenticated and emits the new session', () async {
      final controller = SessionController();
      final statuses = <SessionStatus>[];
      final sessions = <AuthSession?>[];
      final statusSubscription = controller.changes.listen(statuses.add);
      final sessionSubscription = controller.sessionChanges.listen(
        sessions.add,
      );
      const session = AuthSession(userId: 'user-1');

      controller.setSession(session);

      expect(controller.status, SessionStatus.authenticated);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.session, session);
      expect(statuses, [SessionStatus.authenticated]);
      expect(sessions, [session]);

      await statusSubscription.cancel();
      await sessionSubscription.cancel();
      await controller.dispose();
    });

    test('markUnauthenticated clears the session', () async {
      final controller = SessionController(
        initialSession: const AuthSession(userId: 'user-1'),
      );
      final statuses = <SessionStatus>[];
      final subscription = controller.changes.listen(statuses.add);

      controller.markUnauthenticated();

      expect(controller.status, SessionStatus.unauthenticated);
      expect(controller.session, isNull);
      expect(statuses, [SessionStatus.unauthenticated]);
      await subscription.cancel();
      await controller.dispose();
    });

    test('setSession(null) means unauthenticated', () {
      final controller = SessionController();
      controller.setSession(null);

      expect(controller.status, SessionStatus.unauthenticated);
      expect(controller.session, isNull);
    });

    test('markUnknown reports unknown again', () {
      final controller = SessionController(
        initialSession: const AuthSession(userId: 'user-1'),
      );
      controller.markUnknown();

      expect(controller.status, SessionStatus.unknown);
    });

    test('an initial session starts authenticated', () {
      final controller = SessionController(
        initialSession: const AuthSession(userId: 'user-1'),
      );

      expect(controller.status, SessionStatus.authenticated);
      expect(controller.session?.userId, 'user-1');
    });
  });
}
