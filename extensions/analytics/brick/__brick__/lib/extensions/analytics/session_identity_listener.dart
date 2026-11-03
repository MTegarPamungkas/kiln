// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// Keeps the analytics identity in sync with [SessionController].
///
/// A non-null session is identified and a null session resets the identity.
/// Updates run in order, and a failing [Analytics] never breaks sign-in or
/// sign-out. The listener does not identify by itself until [start] is called.
final class SessionIdentityListener {
  SessionIdentityListener({
    required SessionController sessions,
    required Analytics analytics,
    this.identifyCurrentSession = true,
  }) : _sessions = sessions,
       _analytics = analytics;

  final SessionController _sessions;
  final Analytics _analytics;

  /// Whether [start] identifies a session that already existed.
  final bool identifyCurrentSession;

  StreamSubscription<AuthSession?>? _subscription;
  Future<void> _tail = Future<void>.value();

  bool get isRunning => _subscription != null;

  /// Completes when queued identify and reset calls have been applied.
  Future<void> get idle => _tail;

  void start() {
    if (_subscription != null) {
      return;
    }
    _subscription = _sessions.sessionChanges.listen((session) {
      _dispatch(session);
    });
    final current = _sessions.session;
    if (identifyCurrentSession && current != null) {
      _dispatch(current);
    }
  }

  Future<void> dispose() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  void _dispatch(AuthSession? session) {
    _tail = _tail.then((_) => _apply(session));
  }

  Future<void> _apply(AuthSession? session) async {
    try {
      if (session == null) {
        await _analytics.reset();
      } else {
        await _analytics.identify(session.userId);
      }
    } on Object {
      // Analytics must never interfere with session changes.
    }
  }
}
