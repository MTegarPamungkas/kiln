import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'google_credential_gateway.dart';

/// Signs out of Google when the session ends.
final class SocialSignOutListener {
  SocialSignOutListener({required this.auth, required this.google});

  final AuthRepository auth;
  final GoogleCredentialGateway google;
  StreamSubscription<AuthSession?>? _subscription;

  Future<void> start() async {
    _subscription ??= auth.authStateChanges.listen((session) {
      if (session == null) {
        unawaited(_signOutQuietly());
      }
    });
  }

  Future<void> _signOutQuietly() async {
    try {
      await google.signOut();
    } on Object {
      // Signing out of Google is best effort; the app session is already gone.
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
