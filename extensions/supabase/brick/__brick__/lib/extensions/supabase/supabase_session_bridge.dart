// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// Forwards Supabase session changes to the app [SessionController].
///
/// The bridge uses [AuthRepository] as the single source of truth, so
/// `authStateChanges`, `currentSession`, and the app session never diverge.
final class SupabaseSessionBridge {
  SupabaseSessionBridge({
    required AuthRepository auth,
    required SessionController controller,
  }) : _auth = auth,
       _controller = controller;

  final AuthRepository _auth;
  final SessionController _controller;
  StreamSubscription<AuthSession?>? _subscription;
  bool _disposed = false;

  bool get isAttached => _subscription != null;

  /// Seeds the initial session and subscribes to later changes.
  ///
  /// Does nothing after [dispose]; bootstrap may call [start] after disposal
  /// when `ready()` outlived the bootstrapping application.
  void start() {
    if (_subscription != null || _disposed) {
      return;
    }
    _controller.setSession(_auth.currentSession);
    _subscription = _auth.authStateChanges.listen(_controller.setSession);
  }

  /// Stops forwarding changes; the last session is left untouched.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _subscription?.cancel();
    _subscription = null;
  }
}
