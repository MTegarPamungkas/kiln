import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// Expires the shared session when [AuthSession.expiresAt] passes.
///
/// Timers can be suspended while the app is in the background, so
/// [checkNow] is also called when the app resumes.
final class SessionExpiryGuard {
  SessionExpiryGuard({
    required this.session,
    required this.clock,
    this.onExpired,
  });

  final SessionController session;
  final Clock clock;
  final void Function()? onExpired;

  StreamSubscription<AuthSession?>? _subscription;
  Timer? _timer;

  void start() {
    _subscription ??= session.sessionChanges.listen(_schedule);
    _schedule(session.session);
  }

  /// Re-checks the current session, for example after app resume.
  void checkNow() => _schedule(session.session);

  void _schedule(AuthSession? current) {
    _timer?.cancel();
    _timer = null;
    final expiresAt = current?.expiresAt;
    if (expiresAt == null) {
      return;
    }
    final remaining = expiresAt.difference(clock.now());
    if (remaining <= Duration.zero) {
      _expire();
      return;
    }
    _timer = Timer(remaining, _expire);
  }

  void _expire() {
    _timer = null;
    final current = session.session;
    if (current == null || !current.isExpired(clock)) {
      return;
    }
    session.markUnauthenticated();
    onExpired?.call();
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _subscription?.cancel();
    _subscription = null;
  }
}
