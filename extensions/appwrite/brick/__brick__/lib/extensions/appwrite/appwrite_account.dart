import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:http/http.dart' as http;
import 'package:kiln_core/kiln_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User fields the extension needs, independent of the Appwrite models.
final class AppwriteAccountUser {
  const AppwriteAccountUser({
    required this.id,
    required this.email,
    this.name = '',
    this.emailVerified = false,
    this.prefs = const <String, Object?>{},
  });

  final String id;
  final String email;
  final String name;
  final bool emailVerified;
  final Map<String, Object?> prefs;

  String? get displayName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? get photoUrl {
    final value = prefs['photoUrl'];
    return value is String && value.isNotEmpty ? value : null;
  }

  AppwriteAccountUser copyWith({
    String? name,
    bool? emailVerified,
    Map<String, Object?>? prefs,
  }) {
    return AppwriteAccountUser(
      id: id,
      email: email,
      name: name ?? this.name,
      emailVerified: emailVerified ?? this.emailVerified,
      prefs: prefs ?? this.prefs,
    );
  }
}

/// Session handle returned by the Appwrite account service.
final class AppwriteAccountSession {
  const AppwriteAccountSession({
    required this.id,
    required this.userId,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final DateTime? expiresAt;
}

/// The user and session produced by a sign-in.
final class AppwriteAuthResult {
  const AppwriteAuthResult({required this.user, required this.session});

  final AppwriteAccountUser user;
  final AppwriteAccountSession session;
}

/// Appwrite account calls the rest of the extension depends on.
///
/// The interface keeps SDK models out of the auth and account code so both can
/// be exercised with an in-memory fake.
abstract interface class AppwriteAccount {
  /// The signed-in user, or null when the current session is gone.
  Future<AppwriteAccountUser?> currentUser();

  Future<AppwriteAuthResult> signIn({
    required String email,
    required String password,
  });

  Future<AppwriteAccountUser> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> signOut();

  /// Starts an Appwrite OAuth2 session for [provider].
  ///
  /// Launches the provider flow in the browser; on native the resulting session
  /// is delivered through the [successUrl] deep link and captured by the SDK.
  Future<void> createOAuth2Session({
    required SocialProvider provider,
    required String successUrl,
    String? failureUrl,
  });

  Future<void> sendPasswordResetEmail(
    String email, {
    required String redirectUrl,
  });

  Future<void> sendEmailVerification({required String redirectUrl});

  Future<void> updateDisplayName(String displayName);

  Future<void> updatePhotoUrl(String? photoUrl);

  /// Creates a short-lived JWT for the current session, or null when signed out.
  Future<String?> createJwt();
}

/// [AppwriteAccount] on top of the Appwrite `Account` service.
final class SdkAppwriteAccount implements AppwriteAccount {
  SdkAppwriteAccount({required this.account, this.client});

  final Account account;

  /// Shared client that must carry the session header for follow-up calls.
  final Client? client;

  static const _sessionCookieKey = 'kiln.appwrite.session.cookie';

  @override
  Future<AppwriteAccountUser?> currentUser() async {
    await _restoreCookie();
    try {
      return _fromUser(await account.get());
    } on AppwriteException catch (error) {
      if (error.code == 401) {
        await _clearCookie();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AppwriteAuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final session = await _createSession(email: email, password: password);
    final user = await account.get();
    return AppwriteAuthResult(
      user: _fromUser(user),
      session: session,
    );
  }

  /// Creates an email session and forwards its cookie as a session header.
  ///
  /// The Flutter SDK persists cookies asynchronously and its cookie jar does
  /// not survive plain-HTTP endpoints reliably, so the encoded session cookie
  /// is attached explicitly. The server accepts the same value through
  /// `X-Appwrite-Session` for SSR clients.
  Future<AppwriteAccountSession> _createSession({
    required String email,
    required String password,
  }) async {
    final shared = client;
    final project = shared?.config['project'] ?? '';
    if (shared == null || project.isEmpty) {
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return _fromSession(session);
    }

    final response = await http.post(
      Uri.parse('${shared.endPoint}/account/sessions/email'),
      headers: <String, String>{
        'X-Appwrite-Project': project,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{'email': email, 'password': password}),
    );
    if (response.statusCode != 201) {
      throw AppwriteException(
        _responseMessage(response.body),
        response.statusCode,
      );
    }

    final cookie = _sessionCookie(response.headers['set-cookie'], project);
    if (cookie == null) {
      throw AppwriteException(
        'Session cookie missing from the login response.',
        500,
      );
    }
    shared.setSession(cookie);
    await _persistCookie(cookie);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AppwriteAccountSession(
      id: (json[r'$id'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      expiresAt: DateTime.tryParse((json['expire'] as String?) ?? ''),
    );
  }

  String? _sessionCookie(String? setCookie, String project) {
    if (setCookie == null) {
      return null;
    }
    final name = 'a_session_$project';
    for (final part in setCookie.split(RegExp(r',(?=[^ ])'))) {
      final cookie = part.trim();
      if (!cookie.startsWith('$name=')) {
        continue;
      }
      final value = cookie.substring(name.length + 1).split(';').first;
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _responseMessage(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic> && json['message'] is String) {
        return json['message'] as String;
      }
    } on FormatException {
      // Fall through to the raw body.
    }
    return body.isEmpty ? 'Login failed.' : body;
  }

  @override
  Future<AppwriteAccountUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final user = await account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: displayName,
    );
    return _fromUser(user);
  }

  @override
  Future<void> signOut() async {
    try {
      await account.deleteSessions(current: true);
    } on AppwriteException catch (error) {
      if (error.code != 401) {
        rethrow;
      }
    }
    client?.setSession('');
    await _clearCookie();
  }

  @override
  Future<void> createOAuth2Session({
    required SocialProvider provider,
    required String successUrl,
    String? failureUrl,
  }) {
    return account.createOAuth2Session(
      provider: _oauthProvider(provider),
      success: successUrl,
      failure: failureUrl,
    );
  }

  static OAuthProvider _oauthProvider(SocialProvider provider) =>
      switch (provider) {
        SocialProvider.google => OAuthProvider.google,
        SocialProvider.apple => OAuthProvider.apple,
      };

  Future<void> _persistCookie(String cookie) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionCookieKey, cookie);
  }

  Future<void> _restoreCookie() async {
    final shared = client;
    if (shared == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString(_sessionCookieKey) ?? '';
    if (cookie.isNotEmpty) {
      shared.setSession(cookie);
    }
  }

  Future<void> _clearCookie() async {
    if (client == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionCookieKey);
  }

  @override
  Future<void> sendPasswordResetEmail(
    String email, {
    required String redirectUrl,
  }) async {
    await account.createRecovery(email: email, url: redirectUrl);
  }

  @override
  Future<void> sendEmailVerification({required String redirectUrl}) async {
    await account.createEmailVerification(url: redirectUrl);
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    await account.updateName(name: displayName);
  }

  @override
  Future<void> updatePhotoUrl(String? photoUrl) async {
    final current = await account.getPrefs();
    final prefs = Map<String, Object?>.from(current.data);
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      prefs.remove('photoUrl');
    } else {
      prefs['photoUrl'] = photoUrl;
    }
    await account.updatePrefs(prefs: prefs);
  }

  @override
  Future<String?> createJwt() async {
    try {
      final token = await account.createJWT();
      return token.jwt.isEmpty ? null : token.jwt;
    } on AppwriteException catch (error) {
      if (error.code == 401) {
        return null;
      }
      rethrow;
    }
  }

  AppwriteAccountUser _fromUser(models.User user) {
    return AppwriteAccountUser(
      id: user.$id,
      email: user.email,
      name: user.name,
      emailVerified: user.emailVerification,
      prefs: Map<String, Object?>.from(user.prefs.data),
    );
  }

  AppwriteAccountSession _fromSession(models.Session session) {
    return AppwriteAccountSession(
      id: session.$id,
      userId: session.userId,
      expiresAt: DateTime.tryParse(session.expire),
    );
  }
}
