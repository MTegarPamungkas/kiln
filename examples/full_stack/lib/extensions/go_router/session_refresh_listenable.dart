import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

/// Exposes [SessionController] changes as a router refresh signal.
///
/// go_router re-evaluates redirects whenever a [Listenable] passed as
/// `refreshListenable` notifies, so signing in or out applies the auth guard
/// without rebuilding the application.
final class SessionRefreshListenable extends ChangeNotifier {
  SessionRefreshListenable(this.session) {
    _subscription = session.changes.listen(_onSessionChanged);
  }

  final SessionController session;
  late final StreamSubscription<SessionStatus> _subscription;
  bool _disposed = false;

  void _onSessionChanged(SessionStatus status) {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
