import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/analytics/session_identity_listener.dart';

final class _ThrowingAnalytics implements Analytics {
  int calls = 0;

  @override
  Future<void> capture(
    String event, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {
    calls++;
    throw StateError('analytics failed');
  }

  @override
  Future<void> identify(
    String userId, {
    Map<String, Object?> traits = const <String, Object?>{},
  }) async {
    calls++;
    throw StateError('analytics failed');
  }

  @override
  Future<void> reset() async {
    calls++;
    throw StateError('analytics failed');
  }
}

void main() {
  group('SessionIdentityListener', () {
    test('identifies on sign-in and resets on sign-out', () async {
      final sessions = SessionController();
      final analytics = FakeAnalytics();
      final listener = SessionIdentityListener(
        sessions: sessions,
        analytics: analytics,
      )..start();

      sessions.setSession(const AuthSession(userId: 'user-1'));
      await listener.idle;
      sessions.markUnauthenticated();
      await listener.idle;

      expect(analytics.identities, hasLength(1));
      expect(analytics.identities.single.userId, 'user-1');
      expect(analytics.resetCalls, 1);

      await listener.dispose();
      await sessions.dispose();
    });

    test('identifies a session that already existed on start', () async {
      final sessions = SessionController(
        initialSession: const AuthSession(userId: 'user-2'),
      );
      final analytics = FakeAnalytics();
      final listener = SessionIdentityListener(
        sessions: sessions,
        analytics: analytics,
      );

      listener.start();
      await listener.idle;

      expect(analytics.identities.single.userId, 'user-2');

      await listener.dispose();
      await sessions.dispose();
    });

    test('start is idempotent and dispose stops listening', () async {
      final sessions = SessionController();
      final analytics = FakeAnalytics();
      final listener = SessionIdentityListener(
        sessions: sessions,
        analytics: analytics,
      )
        ..start()
        ..start();

      sessions.setSession(const AuthSession(userId: 'user-1'));
      await listener.idle;
      expect(analytics.identities, hasLength(1));

      await listener.dispose();
      expect(listener.isRunning, isFalse);
      sessions.setSession(const AuthSession(userId: 'user-2'));
      await listener.idle;
      expect(analytics.identities, hasLength(1));

      await sessions.dispose();
    });

    test('analytics errors do not escape the listener', () async {
      final sessions = SessionController();
      final analytics = _ThrowingAnalytics();
      final listener = SessionIdentityListener(
        sessions: sessions,
        analytics: analytics,
      )..start();

      sessions.setSession(const AuthSession(userId: 'user-1'));
      await listener.idle;
      sessions.markUnauthenticated();
      await listener.idle;

      expect(analytics.calls, 2);

      await listener.dispose();
      await sessions.dispose();
    });
  });
}
