import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:minimal/core/session/session_expiry_guard.dart';

final class _MutableClock implements Clock {
  _MutableClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration duration) => _now = _now.add(duration);
}

void main() {
  test('expires the session when the deadline passes', () async {
    final clock = _MutableClock(DateTime.now());
    final session = SessionController();
    var expired = 0;
    final guard = SessionExpiryGuard(
      session: session,
      clock: clock,
      onExpired: () => expired += 1,
    )..start();

    session.setSession(
      AuthSession(
        userId: 'user-1',
        expiresAt: clock.now().add(const Duration(milliseconds: 50)),
      ),
    );
    clock.advance(const Duration(milliseconds: 50));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(session.status, SessionStatus.unauthenticated);
    expect(session.session, isNull);
    expect(expired, 1);

    await guard.dispose();
    await session.dispose();
  });

  test('checkNow expires a session that passed while suspended', () async {
    final clock = _MutableClock(DateTime.now());
    final session = SessionController();
    final guard = SessionExpiryGuard(session: session, clock: clock)..start();

    session.setSession(
      AuthSession(
        userId: 'user-1',
        expiresAt: clock.now().add(const Duration(minutes: 5)),
      ),
    );
    clock.advance(const Duration(minutes: 10));

    guard.checkNow();

    expect(session.status, SessionStatus.unauthenticated);

    await guard.dispose();
    await session.dispose();
  });

  test('a new session cancels the previous deadline', () async {
    final clock = _MutableClock(DateTime.now());
    final session = SessionController();
    final guard = SessionExpiryGuard(session: session, clock: clock)..start();

    session.setSession(
      AuthSession(
        userId: 'short',
        expiresAt: clock.now().add(const Duration(milliseconds: 50)),
      ),
    );
    session.setSession(
      AuthSession(
        userId: 'long',
        expiresAt: clock.now().add(const Duration(hours: 1)),
      ),
    );

    clock.advance(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(session.isAuthenticated, isTrue);
    expect(session.session?.userId, 'long');

    await guard.dispose();
    await session.dispose();
  });
}
