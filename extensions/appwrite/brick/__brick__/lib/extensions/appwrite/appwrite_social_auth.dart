import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'appwrite_account.dart';
import 'appwrite_config.dart';
import 'appwrite_failure_mapper.dart';
import 'appwrite_session_bridge.dart';

/// [SocialAuth] implementation on top of Appwrite OAuth2 sessions.
///
/// Appwrite runs social sign-in as a browser redirect: [signIn] launches the
/// provider flow, the SDK captures the returned session from the
/// `appwrite-callback-<project>://` deep link, and this class waits for that
/// session before publishing it through the [AppwriteSessionBridge]. A
/// cancelled or timed-out flow returns `null`, matching the Supabase
/// implementation so callers can treat `null` as "the user backed out".
final class AppwriteSocialAuth implements SocialAuth {
  AppwriteSocialAuth({
    required AppwriteAccount account,
    required AppwriteConfig config,
    required AppwriteSessionBridge bridge,
    Duration timeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(milliseconds: 250),
    AppwriteFailureMapper failureMapper = const AppwriteFailureMapper(),
  }) : _account = account,
       _config = config,
       _bridge = bridge,
       _timeout = timeout,
       _pollInterval = pollInterval,
       _failures = failureMapper;

  final AppwriteAccount _account;
  final AppwriteConfig _config;
  final AppwriteSessionBridge _bridge;
  final Duration _timeout;
  final Duration _pollInterval;
  final AppwriteFailureMapper _failures;

  @override
  Future<SocialCredential?> signIn(SocialProvider provider) async {
    await _guard(
      () => _account.createOAuth2Session(
        provider: provider,
        successUrl: _config.oAuthSuccessUrl,
      ),
    );
    final user = await _waitForUser();
    if (user == null) {
      return null;
    }
    _bridge.establish(user: user);
    final token = await _guard(_account.createJwt);
    return SocialCredential(
      provider: provider,
      // Appwrite verifies the identity on the server, so the token a caller can
      // hold locally is the session JWT for the account that just signed in.
      idToken: token ?? '',
      accessToken: token,
      email: user.email.isEmpty ? null : user.email,
      displayName: user.displayName,
    );
  }

  @override
  Future<void> signOut() async {
    await _guard(_account.signOut);
    _bridge.clear();
  }

  Future<AppwriteAccountUser?> _waitForUser() async {
    final deadline = DateTime.now().add(_timeout);
    while (DateTime.now().isBefore(deadline)) {
      final user = await _guard(_account.currentUser);
      if (user != null) {
        return user;
      }
      await Future<void>.delayed(_pollInterval);
    }
    return null;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      throw _failures.map(
        error,
        scope: AppwriteFailureScope.auth,
        stackTrace: stackTrace,
      );
    }
  }
}
