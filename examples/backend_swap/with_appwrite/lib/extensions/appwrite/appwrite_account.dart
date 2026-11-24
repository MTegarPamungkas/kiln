import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:kiln_core/kiln_core.dart';

import 'appwrite_login_client.dart';
import 'appwrite_oauth_launcher.dart';
import 'appwrite_session_store.dart';

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
  SdkAppwriteAccount({
    required this.account,
    this.client,
    this.flavor = AppFlavor.production,
    this.requestTimeout = const Duration(seconds: 15),
    AppwriteSessionStore sessionStore = const PreferencesAppwriteSessionStore(),
    this._loginClient,
  }) : _store = sessionStore;

  final AppFlavor flavor;
  final Duration requestTimeout;
  final AppwriteSessionStore _store;
  final http.Client? _loginClient;
  int _generation = 0;
  Future<void> _operations = Future<void>.value();

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _operations.then((_) => action());
    _operations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  final Account account;

  /// Shared client that must carry the session header for follow-up calls.
  final Client? client;

  /// Legacy unscoped key. It is never restored because ownership is unknown.
  static const sessionCookieKey = appwriteLegacySessionCookieKey;
  static String sessionCookieKeyFor(String endpoint, String projectId) =>
      '$sessionCookieKey.${base64Url.encode(utf8.encode(jsonEncode([endpoint.replaceFirst(RegExp(r'/+$'), ''), projectId])))}';

  String get _sessionCookieKey => sessionCookieKeyFor(
    _transport.endPoint,
    _transport.config['project'] ?? '',
  );
  Client get _transport => client ?? account.client;
  String get _signedOutKey =>
      'kiln.appwrite.signedOut.${_transport.endPoint}.${_transport.config['project']}';
  bool _locallySignedOut = false;

  Future<bool> _isSignedOut() async =>
      _locallySignedOut || await _store.read(_signedOutKey) == 'true';

  Future<void> _allowSession({int? generation}) async {
    await _store.delete(_signedOutKey);
    if (generation != null) _checkGeneration(generation);
    _locallySignedOut = false;
  }

  /// Mirrors the session into the SDK cookie jar when the client keeps one.
  ///
  /// REST calls authenticate through the explicit `X-Appwrite-Session` header,
  /// but realtime authenticates at the WebSocket handshake with cookies from
  /// the jar, so the jar must know the session too. Missing jar support (older
  /// SDK shapes) is ignored; those setups keep header-based sessions.
  Future<void> _seedCookieJar(String cookie) async {
    final shared = client;
    if (shared == null) {
      return;
    }
    // The SDK exposes no public type for its cookie jar, so this one seam has
    // to cross into it dynamically.
    try {
      // ignore: avoid_dynamic_calls
      final jar = (shared as dynamic).cookieJar;
      if (jar == null) {
        return;
      }
      final uri = Uri.parse(shared.endPoint);
      // ignore: avoid_dynamic_calls
      await jar.saveFromResponse(uri, <Cookie>[
        Cookie.fromSetCookieValue(
          'a_session_${shared.config['project']}=$cookie; Path=/',
        ),
      ]);
    } on Object {
      // Header-based sessions keep working without a jar.
    }
  }

  Future<void> _clearCookieJar() async {
    final shared = client;
    if (shared == null) {
      return;
    }
    dynamic jar;
    try {
      // ignore: avoid_dynamic_calls
      jar = (shared as dynamic).cookieJar;
    } on Object {
      // A client without a cookie jar has no native cache to clear.
      return;
    }
    // ignore: avoid_dynamic_calls
    await jar?.delete(Uri.parse(shared.endPoint));
  }

  @override
  Future<AppwriteAccountUser?> currentUser() {
    final generation = _generation;
    return _serialize(() => _currentUser(generation));
  }

  Future<AppwriteAccountUser?> _currentUser(int generation) async {
    if (generation != _generation) return null;
    if (await _isSignedOut()) return null;
    await _restoreCookie();
    try {
      final user = await account.get().timeout(requestTimeout);
      return generation != _generation || await _isSignedOut()
          ? null
          : _fromUser(user);
    } on AppwriteException catch (error) {
      if (error.code == 401) {
        if (generation != _generation) return null;
        _resetTransportCredentials();
        try {
          await _clearCookie();
        } catch (error) {
          throw _cleanupFailure(error);
        }
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AppwriteAuthResult> signIn({
    required String email,
    required String password,
  }) {
    final generation = ++_generation;
    return _serialize(() => _signIn(email, password, generation));
  }

  Future<AppwriteAuthResult> _signIn(
    String email,
    String password,
    int generation,
  ) async {
    _checkGeneration(generation);
    try {
      final session = await _createSession(
        email: email,
        password: password,
        generation: generation,
      );
      final user = await account.get().timeout(requestTimeout);
      _checkGeneration(generation);
      final cookie = _transport.config['session'];
      if (cookie != null && cookie.isNotEmpty) await _seedCookieJar(cookie);
      _checkGeneration(generation);
      await _allowSession(generation: generation);
      _checkGeneration(generation);
      return AppwriteAuthResult(user: _fromUser(user), session: session);
    } catch (_) {
      _locallySignedOut = true;
      _resetTransportCredentials();
      try {
        await Future.wait([_rememberSignOut(), _clearCookie()]);
      } catch (error) {
        throw _cleanupFailure(error);
      }
      rethrow;
    }
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
    required int generation,
  }) async {
    final shared = client;
    final project = shared?.config['project'] ?? '';
    if (kIsWeb || shared == null || project.isEmpty) {
      final session = await account
          .createEmailPasswordSession(email: email, password: password)
          .timeout(requestTimeout);
      _checkGeneration(generation);
      return _fromSession(session);
    }

    final transport = _loginClient ?? createAppwriteLoginClient(flavor);
    final http.Response response;
    try {
      response = await transport
          .post(
            Uri.parse(
              '${shared.endPoint.replaceFirst(RegExp(r'/+$'), '')}/account/sessions/email',
            ),
            headers: <String, String>{
              'X-Appwrite-Project': project,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'email': email,
              'password': password,
            }),
          )
          .timeout(requestTimeout);
    } finally {
      if (_loginClient == null) transport.close();
    }
    _checkGeneration(generation);
    if (response.statusCode != 201) {
      throw AppwriteException(
        _responseMessage(response.body),
        response.statusCode,
        _responseType(response.body),
      );
    }

    final cookie = _sessionCookie(response.headers['set-cookie'], project);
    if (cookie == null) {
      throw AppwriteException(
        'Session cookie missing from the login response.',
        500,
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _checkGeneration(generation);
    shared.setSession(cookie);
    await _persistCookie(cookie);
    if (generation != _generation) {
      await _clearCookie();
      _checkGeneration(generation);
    }
    await _seedCookieJar(cookie);
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
    final name = RegExp.escape('a_session_$project');
    final match = RegExp('(?:^|,\\s*)$name=([^;\\s,]+)').firstMatch(setCookie);
    return match == null ? null : _decodeCookie(match.group(1)!);
  }

  /// Appwrite 2.7+ URL-encodes the session cookie value; the server only
  /// accepts the decoded form in `X-Appwrite-Session` and the cookie jar.
  String _decodeCookie(String value) {
    try {
      return Uri.decodeComponent(value);
    } on FormatException {
      return value;
    }
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
    return 'Appwrite login failed.';
  }

  String? _responseType(String body) {
    try {
      final json = jsonDecode(body);
      return json is Map && json['type'] is String
          ? json['type'] as String
          : null;
    } on FormatException {
      return null;
    }
  }

  void _checkGeneration(int generation) {
    if (generation != _generation) {
      throw const Failure(
        code: FailureCode.authCancelled,
        message: 'The authentication operation was superseded.',
        kind: FailureKind.authentication,
      );
    }
  }

  void _resetTransportCredentials() {
    for (final shared in {_transport, account.client}) {
      Map<String, String> headers;
      try {
        headers = shared.getHeaders();
      } on Object {
        headers = const {};
      }
      bool present(String name, String header) =>
          (shared.config[name]?.isNotEmpty ?? false) || headers.entries.any(
            (entry) => entry.key.toLowerCase() == header && entry.value.isNotEmpty);
      // Setters add headers even for empty values. Adding an unused Authorization
      // header after a 401 can make the next browser request fail CORS preflight.
      if (present('session', 'x-appwrite-session')) shared.setSession('');
      if (present('cookie', 'cookie')) shared.setCookie('');
      if (present('jWT', 'x-appwrite-jwt')) shared.setJWT('');
      if (present('bearer', 'authorization')) shared.setBearer('');
    }
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
  Future<void> signOut() {
    cancelOAuth();
    _locallySignedOut = true;
    _generation++;
    return _serialize(_signOut);
  }

  Future<void> _signOut() async {
    Object? cleanupError;
    try {
      await account.deleteSessions(current: true).timeout(requestTimeout);
    } on Object {
      // Revocation is best-effort; local logout must work offline.
    } finally {
      _resetTransportCredentials();
      try {
        await Future.wait<void>([_rememberSignOut(), _clearCookie()]);
      } on Object catch (error) {
        cleanupError = error;
      }
    }
    if (cleanupError != null) {
      throw _cleanupFailure(cleanupError);
    }
  }

  Failure _cleanupFailure(Object error) => Failure(
    code: FailureCode.unavailable,
    message: 'Local Appwrite session cleanup could not be completed.',
    kind: FailureKind.authentication,
    cause: error,
    details: const {'localCleanupFailed': true},
  );

  Future<void> _rememberSignOut() async {
    await _store.write(_signedOutKey, 'true');
  }

  @override
  Future<void> createOAuth2Session({
    required SocialProvider provider,
    required String successUrl,
    String? failureUrl,
  }) async {
    // A new sign-in attempt overrides an earlier local logout marker.
    final generation = ++_generation;
    await _allowSession(generation: generation);
    return launchAppwriteOAuth(account,
      provider: _oauthProvider(provider),
      successUrl: successUrl,
      failureUrl: failureUrl,
    );
  }

  /// Closes an interactive web popup and releases its callbacks.
  void cancelOAuth() => cancelAppwriteOAuth(account);

  static OAuthProvider _oauthProvider(SocialProvider provider) =>
      switch (provider) {
        SocialProvider.google => OAuthProvider.google,
        SocialProvider.apple => OAuthProvider.apple,
      };

  Future<void> _persistCookie(String cookie) async {
    await _store.write(_sessionCookieKey, cookie);
  }

  Future<void> _restoreCookie() async {
    final shared = client;
    if (shared == null) {
      return;
    }
    final generation = _generation;
    final stored = await _store.read(_sessionCookieKey) ?? '';
    if (generation != _generation || _locallySignedOut) return;
    // Scoped values are already decoded when the login response is persisted.
    final cookie = stored;
    if (cookie.isNotEmpty) {
      shared.setSession(cookie);
      await _seedCookieJar(cookie);
    }
  }

  Future<void> _clearCookie() async {
    if (client == null) {
      return;
    }
    await Future.wait([
      _store.delete(_sessionCookieKey),
      _store.delete(sessionCookieKey),
      _clearCookieJar(),
    ]);
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
    final generation = _generation;
    if (await _isSignedOut()) return null;
    try {
      final token = await account.createJWT().timeout(requestTimeout);
      if (generation != _generation || await _isSignedOut()) return null;
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
