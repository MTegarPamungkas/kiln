import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'firebase_auth_repository.dart';
import 'firebase_gateway.dart';

/// Forwards Firebase Auth state to the shared [SessionController].
///
/// The bridge is the only place that writes Firebase identity into the session
/// layer, so `AuthRepository` and the application see the same session.
final class FirebaseSessionBridge implements Disposable {
  FirebaseSessionBridge({
    required this.controller,
    required this.users,
    this.toSession = sessionForFirebaseUser,
  });

  final SessionController controller;

  /// Resolved on [start] so the module can register before
  /// `Firebase.initializeApp` runs.
  final Stream<FirebaseUser?> Function() users;
  final AuthSession? Function(FirebaseUser? user) toSession;

  StreamSubscription<FirebaseUser?>? _subscription;

  bool get isRunning => _subscription != null;

  /// Starts listening; calling this twice is a no-op.
  void start() {
    _subscription ??= users().listen((user) {
      controller.setSession(toSession(user));
    });
  }

  /// Stops listening while keeping the last session in place.
  Future<void> stop() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  @override
  Future<void> dispose() => stop();
}
