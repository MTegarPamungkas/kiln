import 'dart:async';

// ignore_for_file: prefer_initializing_formals

import 'package:flutter/services.dart';
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
    final revision = _bridge.beginOperation();
    try {
      await _account.createOAuth2Session(
        provider: provider,
        successUrl: _config.oAuthSuccessUrl,
      );
    } on PlatformException catch (error, stackTrace) {
      if (error.code == 'CANCELED' || error.code == 'CANCELLED') return null;
      throw _failures.map(
        error,
        scope: AppwriteFailureScope.auth,
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      throw _failures.map(
        error,
        scope: AppwriteFailureScope.auth,
        stackTrace: stackTrace,
      );
    }
    final user = await _waitForUser(revision);
    if (revision != _bridge.revision) return null;
    if (user == null) {
      return null;
    }
    final token = await _guard(_account.createJwt);
    if (revision != _bridge.revision) return null;
    _bridge.establish(user: user);
    return SocialCredential(
      provider: provider,
      // Appwrite verified the identity on its server; the token available here
      // is the Appwrite session JWT, not a provider identity token.
      idToken: token ?? '',
      audience: SocialTokenAudience.backend,
      backendSessionToken: token,
      email: user.email.isEmpty ? null : user.email,
      displayName: user.displayName,
    );
  }

  @override
  Future<void> signOut() async {
    _bridge.clear();
    await _guard(_account.signOut);
  }

  Future<AppwriteAccountUser?> _waitForUser(int revision) async {
    final deadline = DateTime.now().add(_timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (revision != _bridge.revision) return null;
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
