// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kiln_core/kiln_core.dart';

/// A signed-in Neon Auth (Better Auth) session.
final class NeonAuthSession {
  const NeonAuthSession({
    required this.userId,
    required this.email,
    this.displayName,
    this.sessionToken = '',
  });

  final String userId;
  final String email;
  final String? displayName;

  /// Opaque Better Auth session token, sent back as the session cookie.
  final String sessionToken;
}

/// Neon Auth (Better Auth) operations, wrapped so the HTTP flow can be faked.
abstract interface class NeonAuthGateway {
  Future<NeonAuthSession> signIn({
    required String email,
    required String password,
  });

  Future<NeonAuthSession> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> signOut();

  Future<NeonAuthSession?> currentSession();

  /// The Data API JWT for the current user (`GET {authUrl}/token`), or null
  /// when signed out. Cached until just before its `exp` claim.
  Future<String?> accessJwt();
}

/// [NeonAuthGateway] backed by Better Auth's HTTP API.
///
/// The gateway keeps the session in memory and re-sends its token as the
/// `__Secure-neon-auth.session_token` cookie on authenticated calls. Sign-in
/// failures map to `Failure(auth.invalid_credentials)`.
final class BetterAuthGateway implements NeonAuthGateway {
  BetterAuthGateway({
    required this.authUrl,
    http.Client? client,
    this.clock = const SystemClock(),
  }) : _client = client ?? http.Client();

  final String authUrl;
  final http.Client _client;
  final Clock clock;

  NeonAuthSession? _session;
  String? _jwt;
  DateTime? _jwtExpires;

  String get _origin {
    final uri = Uri.tryParse(authUrl);
    return uri == null ? '' : '${uri.scheme}://${uri.host}';
  }

  Map<String, String> get _jsonHeaders => <String, String>{
    'content-type': 'application/json',
    'origin': _origin,
  };

  Map<String, String> _cookieHeaders(String token) => <String, String>{
    'origin': _origin,
    'cookie': '__Secure-neon-auth.session_token=$token',
  };

  @override
  Future<NeonAuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$authUrl/sign-in/email'),
      headers: _jsonHeaders,
      body: jsonEncode(<String, String>{'email': email, 'password': password}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Failure(
        code: FailureCode.authInvalidCredentials,
        message: _message(response.body, 'Invalid email or password.'),
        kind: FailureKind.authentication,
      );
    }
    return _adopt(jsonDecode(response.body) as Map<String, Object?>);
  }

  @override
  Future<NeonAuthSession> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _client.post(
      Uri.parse('$authUrl/sign-up/email'),
      headers: _jsonHeaders,
      body: jsonEncode(<String, Object?>{
        'email': email,
        'password': password,
        'name': displayName ?? email,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Failure(
        code: FailureCode.authInvalidCredentials,
        message: _message(response.body, 'The account could not be created.'),
        kind: FailureKind.authentication,
      );
    }
    return _adopt(jsonDecode(response.body) as Map<String, Object?>);
  }

  @override
  Future<void> signOut() async {
    final token = _session?.sessionToken;
    if (token != null && token.isNotEmpty) {
      try {
        await _client.post(
          Uri.parse('$authUrl/sign-out'),
          headers: _cookieHeaders(token),
        );
      } on Object {
        // Signing out locally even when the remote call fails.
      }
    }
    _session = null;
    _jwt = null;
    _jwtExpires = null;
  }

  @override
  Future<NeonAuthSession?> currentSession() async => _session;

  @override
  Future<String?> accessJwt() async {
    final session = _session;
    if (session == null) {
      return null;
    }
    final cached = _jwt;
    final expires = _jwtExpires;
    if (cached != null &&
        expires != null &&
        expires.isAfter(clock.now().add(const Duration(minutes: 1)))) {
      return cached;
    }
    final response = await _client.get(
      Uri.parse('$authUrl/token'),
      headers: _cookieHeaders(session.sessionToken),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final body = jsonDecode(response.body) as Map<String, Object?>;
    final token = body['token'] as String?;
    if (token == null) {
      return null;
    }
    _jwt = token;
    _jwtExpires = _jwtExpiry(token);
    return token;
  }

  void close() => _client.close();

  NeonAuthSession _adopt(Map<String, Object?> body) {
    final user = body['user'] is Map<String, Object?>
        ? body['user'] as Map<String, Object?>
        : body;
    final session = NeonAuthSession(
      userId: '${user['id'] ?? ''}',
      email: '${user['email'] ?? ''}',
      displayName: user['name'] is String ? user['name'] as String : null,
      sessionToken: '${body['token'] ?? ''}',
    );
    _session = session;
    _jwt = null;
    _jwtExpires = null;
    return session;
  }

  static String _message(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } on FormatException {
      // fall through
    }
    return fallback;
  }

  static DateTime? _jwtExpiry(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, Object?>;
      final exp = payload['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      }
    } on FormatException {
      // fall through
    }
    return null;
  }
}
