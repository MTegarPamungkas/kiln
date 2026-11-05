import 'dart:async';

import 'session.dart';

/// Whether the application knows who the user is.
enum SessionStatus { unknown, authenticated, unauthenticated }

/// Holds the current [AuthSession] and notifies listeners of changes.
final class SessionController {
  SessionController({
    SessionStatus initialStatus = SessionStatus.unknown,
    AuthSession? initialSession,
  }) : _session = initialSession,
       _status = initialSession != null
           ? SessionStatus.authenticated
           : initialStatus;

  AuthSession? _session;
  SessionStatus _status;
  final StreamController<SessionStatus> _changes =
      StreamController<SessionStatus>.broadcast(sync: true);
  final StreamController<AuthSession?> _sessions =
      StreamController<AuthSession?>.broadcast(sync: true);

  SessionStatus get status => _status;

  AuthSession? get session => _session;

  bool get isAuthenticated => _status == SessionStatus.authenticated;

  Stream<SessionStatus> get changes => _changes.stream;

  Stream<AuthSession?> get sessionChanges => _sessions.stream;

  void setSession(AuthSession? session) {
    _session = session;
    _emit(
      session == null
          ? SessionStatus.unauthenticated
          : SessionStatus.authenticated,
    );
  }

  void markUnauthenticated() {
    _session = null;
    _emit(SessionStatus.unauthenticated);
  }

  void markUnknown() {
    _emit(SessionStatus.unknown);
  }

  void _emit(SessionStatus status) {
    _status = status;
    _changes.add(status);
    _sessions.add(_session);
  }

  Future<void> dispose() async {
    await _changes.close();
    await _sessions.close();
  }
}
