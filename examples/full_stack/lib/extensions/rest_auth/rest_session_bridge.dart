import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// Mirrors [AuthRepository] changes into [SessionController].
final class RestSessionBridge {
  RestSessionBridge({required this.auth, required this.session});

  final AuthRepository auth;
  final SessionController session;
  StreamSubscription<AuthSession?>? _subscription;
  bool _disposed = false;

  Future<void> start() async {
    if (_disposed) {
      return;
    }
    _subscription ??= auth.authStateChanges.listen(session.setSession);
    final current = auth.currentSession;
    if (current != null) {
      session.setSession(current);
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _subscription?.cancel();
    _subscription = null;
  }
}
