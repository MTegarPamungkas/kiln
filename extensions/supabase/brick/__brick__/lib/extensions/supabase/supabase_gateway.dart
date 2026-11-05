// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';
import 'supabase_failure_mapper.dart';

/// Snapshot of one Supabase session that does not depend on SDK types.
final class SupabaseSession {
  const SupabaseSession({
    required this.userId,
    this.email,
    this.displayName,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.emailVerified = false,
    this.metadata = const <String, Object?>{},
  });

  final String userId;
  final String? email;
  final String? displayName;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final bool emailVerified;

  /// Supabase `user_metadata` contents, for example `display_name`.
  final Map<String, Object?> metadata;

  bool get isAuthenticated => userId.isNotEmpty;

  bool isExpired(DateTime now) {
    final expiry = expiresAt;
    return expiry != null && !expiry.isAfter(now);
  }

  @override
  bool operator ==(Object other) =>
      other is SupabaseSession &&
      other.userId == userId &&
      other.email == email &&
      other.displayName == displayName &&
      other.accessToken == accessToken &&
      other.emailVerified == emailVerified;

  @override
  int get hashCode =>
      Object.hash(userId, email, displayName, accessToken, emailVerified);

  @override
  String toString() => 'SupabaseSession($userId)';
}

/// Supabase operations used by the extension, wrapped so they can be faked.
abstract interface class SupabaseGateway {
  /// Active session according to the SDK.
  SupabaseSession? get currentSession;

  /// Session changes from `onAuthStateChange`.
  Stream<SupabaseSession?> get authStateChanges;

  /// Whether the active user email has been confirmed.
  bool get isEmailVerified;

  /// Reads the session restored by the SDK when the app starts.
  Future<SupabaseSession?> restoreSession();

  Future<SupabaseSession> signInWithPassword({
    required String email,
    required String password,
  });

  /// Null when sign up is waiting for email confirmation.
  Future<SupabaseSession?> signUp({
    required String email,
    required String password,
    String? displayName,
    String? redirectTo,
  });

  Future<void> signOut();

  Future<String?> accessToken({bool forceRefresh = false});

  Future<SupabaseSession> signInWithIdToken({
    required SocialProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  });

  /// Opens the OAuth page; false means the browser could not be launched.
  Future<bool> signInWithOAuth({
    required SocialProvider provider,
    String? redirectTo,
    List<String> scopes = const <String>[],
  });

  Future<SupabaseSession> exchangeCodeForSession(String code);

  Future<SupabaseSession> verifyOtp({
    required String tokenHash,
    required String type,
  });

  Future<void> refreshUser();

  Future<void> sendPasswordResetEmail(String email, {String? redirectTo});

  Future<void> sendEmailVerification({String? redirectTo});

  Future<void> updateUser({
    String? email,
    String? password,
    Map<String, Object?>? data,
    String? redirectTo,
  });
}

/// [SupabaseGateway] backed by `supabase_flutter`.
final class SdkSupabaseGateway implements SupabaseGateway {
  SdkSupabaseGateway({required SupabaseClientProvider provider})
    : _provider = provider;

  final SupabaseClientProvider _provider;

  /// Result of `getUser()` that is not reflected in the stored session yet.
  User? _refreshedUser;

  GoTrueClient get _auth => _provider.client.auth;

  User? get _user {
    final refreshed = _refreshedUser;
    final current = _auth.currentUser;
    if (refreshed != null && current?.id == refreshed.id) {
      return refreshed;
    }
    return current;
  }

  @override
  SupabaseSession? get currentSession => _toSession(_auth.currentSession);

  @override
  Stream<SupabaseSession?> get authStateChanges =>
      _auth.onAuthStateChange.map((state) => _toSession(state.session));

  @override
  bool get isEmailVerified {
    if (!_provider.isReady) {
      return false;
    }
    return _user?.emailConfirmedAt != null;
  }

  @override
  Future<SupabaseSession?> restoreSession() async {
    return _toSession(_auth.currentSession);
  }

  @override
  Future<SupabaseSession> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _guard(
      () async {
        final response = await _auth.signInWithPassword(
          email: email,
          password: password,
        );
        return _requireSession(response.session);
      },
      code: FailureCode.authUnauthorized,
      kind: FailureKind.authentication,
    );
  }

  @override
  Future<SupabaseSession?> signUp({
    required String email,
    required String password,
    String? displayName,
    String? redirectTo,
  }) {
    return _guard(
      () async {
        final response = await _auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: redirectTo,
          data: displayName == null
              ? null
              : <String, dynamic>{'display_name': displayName},
        );
        return _toSession(response.session);
      },
      code: FailureCode.authUnauthorized,
      kind: FailureKind.authentication,
    );
  }

  @override
  Future<void> signOut() {
    return _guard(
      () async {
        await _auth.signOut();
        _refreshedUser = null;
      },
      code: FailureCode.authSessionExpired,
      kind: FailureKind.session,
    );
  }

  @override
  Future<String?> accessToken({bool forceRefresh = false}) {
    return _guard(
      () async {
        if (forceRefresh) {
          await _auth.refreshSession();
        }
        final token = _auth.currentSession?.accessToken;
        return token == null || token.isEmpty ? null : token;
      },
      code: FailureCode.authSessionExpired,
      kind: FailureKind.session,
    );
  }

  @override
  Future<SupabaseSession> signInWithIdToken({
    required SocialProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) {
    return _guard(
      () async {
        final response = await _auth.signInWithIdToken(
          provider: _oauthProvider(provider),
          idToken: idToken,
          accessToken: accessToken,
          nonce: nonce,
        );
        return _requireSession(response.session);
      },
      code: FailureCode.authUnauthorized,
      kind: FailureKind.authentication,
    );
  }

  @override
  Future<bool> signInWithOAuth({
    required SocialProvider provider,
    String? redirectTo,
    List<String> scopes = const <String>[],
  }) {
    return _guard(
      () => _auth.signInWithOAuth(
        _oauthProvider(provider),
        redirectTo: redirectTo,
        scopes: scopes.isEmpty ? null : scopes.join(' '),
      ),
      code: FailureCode.authUnauthorized,
      kind: FailureKind.authentication,
    );
  }

  @override
  Future<SupabaseSession> exchangeCodeForSession(String code) {
    return _guard(
      () async {
        final response = await _auth.exchangeCodeForSession(code);
        return _requireSession(response.session);
      },
      code: FailureCode.authSessionExpired,
      kind: FailureKind.session,
    );
  }

  @override
  Future<SupabaseSession> verifyOtp({
    required String tokenHash,
    required String type,
  }) {
    return _guard(
      () async {
        final response = await _auth.verifyOTP(
          tokenHash: tokenHash,
          type: _otpType(type),
        );
        return _requireSession(response.session);
      },
      code: FailureCode.authSessionExpired,
      kind: FailureKind.session,
    );
  }

  @override
  Future<void> refreshUser() {
    return _guard(
      () async {
        final response = await _auth.getUser();
        _refreshedUser = response.user;
      },
      code: FailureCode.authUnauthorized,
      kind: FailureKind.authentication,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email, {String? redirectTo}) {
    return _guard(
      () => _auth.resetPasswordForEmail(email, redirectTo: redirectTo),
      code: FailureCode.authUnauthorized,
      kind: FailureKind.authentication,
    );
  }

  @override
  Future<void> sendEmailVerification({String? redirectTo}) {
    return _guard(
      () async {
        final email = _user?.email;
        if (email == null || email.isEmpty) {
          throw const Failure(
            code: FailureCode.authSessionExpired,
            message: 'There is no active session to send an email verification.',
            kind: FailureKind.session,
          );
        }
        await _auth.resend(
          email: email,
          type: OtpType.signup,
          emailRedirectTo: redirectTo,
        );
      },
      code: FailureCode.authUnauthorized,
      kind: FailureKind.authentication,
    );
  }

  @override
  Future<void> updateUser({
    String? email,
    String? password,
    Map<String, Object?>? data,
    String? redirectTo,
  }) {
    return _guard(
      () async {
        await _auth.updateUser(
          UserAttributes(email: email, password: password, data: data),
          emailRedirectTo: redirectTo,
        );
        _refreshedUser = null;
      },
      code: FailureCode.authUnauthorized,
      kind: FailureKind.authentication,
    );
  }

  Future<T> _guard<T>(
    Future<T> Function() action, {
    required FailureCode code,
    required FailureKind kind,
  }) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(
        error,
        stackTrace: stackTrace,
        fallbackCode: code,
        fallbackKind: kind,
      );
    }
  }

  SupabaseSession _requireSession(Session? session) {
    final mapped = _toSession(session);
    if (mapped == null) {
      throw const Failure(
        code: FailureCode.authSessionExpired,
        message: 'The Supabase session is unavailable after the auth operation.',
        kind: FailureKind.session,
      );
    }
    return mapped;
  }

  SupabaseSession? _toSession(Session? session) {
    if (session == null) {
      return null;
    }
    final user = session.user;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final expiresAt = session.expiresAt;
    return SupabaseSession(
      userId: user.id,
      email: user.email,
      displayName:
          _text(metadata['display_name']) ??
          _text(metadata['full_name']) ??
          _text(metadata['name']),
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: expiresAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000, isUtc: true),
      emailVerified: user.emailConfirmedAt != null,
      metadata: Map<String, Object?>.from(metadata),
    );
  }

  String? _text(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  OAuthProvider _oauthProvider(SocialProvider provider) {
    return switch (provider) {
      SocialProvider.google => OAuthProvider.google,
      SocialProvider.apple => OAuthProvider.apple,
    };
  }

  OtpType _otpType(String type) {
    return switch (type.toLowerCase()) {
      'signup' => OtpType.signup,
      'invite' => OtpType.invite,
      'recovery' => OtpType.recovery,
      'magiclink' => OtpType.magiclink,
      'email' => OtpType.email,
      'email_change' => OtpType.emailChange,
      'sms' => OtpType.sms,
      'phone_change' => OtpType.phoneChange,
      _ => throw Failure(
        code: FailureCode.validationUnsupportedValue,
        message: 'The OTP type "$type" is not supported yet.',
        kind: FailureKind.validation,
      ),
    };
  }
}
