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
/// `__Secure-neon-auth.session_token` cookie on authenticated calls. Bad
/// credentials map to `Failure(auth.invalid_credentials)`; rejections Better
/// Auth classifies as input problems (taken email, weak password) map to
/// `validation.invalid_input`, and server or rate-limit errors stay retryable
/// instead of blaming the credentials.
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
      throw _failureFor(response, fallback: 'Invalid email or password.');
    }
    return _adoptSession(response.body);
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
      throw _failureFor(response, fallback: 'The account could not be created.');
    }
    return _adoptSession(response.body);
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
    final body = _decodeBody(response.body);
    if (body == null) {
      return null;
    }
    final token = body['token'] as String?;
    if (token == null) {
      return null;
    }
    _jwt = token;
    _jwtExpires = _jwtExpiry(token);
    return token;
  }

  void close() => _client.close();

  /// Decodes a successful sign-in/sign-up body so a response the gateway
  /// cannot read becomes a [Failure] instead of a raw decoding error.
  NeonAuthSession _adoptSession(String body) {
    final decoded = _decodeBody(body);
    if (decoded == null) {
      throw const Failure(
        code: FailureCode.unexpected,
        message: 'Neon Auth returned a response we could not read.',
        kind: FailureKind.authentication,
      );
    }
    return _adopt(decoded);
  }

  /// Decodes a JSON object body, or null when it is not readable JSON.
  static Map<String, Object?>? _decodeBody(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return null;
    }
    return decoded is Map<String, Object?> ? decoded : null;
  }

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

  /// Maps a non-2xx Better Auth response to a [Failure].
  ///
  /// Better Auth answers with a JSON body carrying an upper-snake `code`, for
  /// example `INVALID_EMAIL_OR_PASSWORD` or `USER_ALREADY_EXISTS`. Server
  /// errors and rate limits must not read as bad credentials, so they map to
  /// retryable network/unavailable failures first; rejections Better Auth
  /// classifies as input problems follow the validation codes.
  static Failure _failureFor(
    http.Response response, {
    required String fallback,
  }) {
    final status = response.statusCode;
    final details = <String, Object?>{'statusCode': status};
    if (status >= 500) {
      return Failure(
        code: FailureCode.networkServer,
        message: 'Neon Auth could not complete the request. Try again later.',
        kind: FailureKind.network,
        isRetryable: true,
        details: details,
      );
    }
    if (status == 429) {
      return Failure(
        code: FailureCode.unavailable,
        message: 'Too many attempts. Try again in a moment.',
        kind: FailureKind.unavailable,
        isRetryable: true,
        details: details,
      );
    }
    final code = _errorCode(response.body);
    if (code != null) {
      details['better_auth_code'] = code;
    }
    switch (code) {
      case 'USER_ALREADY_EXISTS':
        return Failure(
          code: FailureCode.validationInvalidInput,
          message: 'An account with this email already exists.',
          kind: FailureKind.validation,
          details: details,
        );
      case 'INVALID_EMAIL':
      case 'INVALID_PASSWORD':
      case 'PASSWORD_TOO_SHORT':
      case 'PASSWORD_TOO_LONG':
        return Failure(
          code: FailureCode.validationInvalidInput,
          message: _message(response.body, fallback),
          kind: FailureKind.validation,
          details: details,
        );
      default:
        return Failure(
          code: FailureCode.authInvalidCredentials,
          message: _message(response.body, fallback),
          kind: FailureKind.authentication,
          details: details,
        );
    }
  }

  /// Better Auth's upper-snake error code, or null on a non-JSON body.
  static String? _errorCode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['code'] is String) {
        return decoded['code'] as String;
      }
    } on FormatException {
      // fall through to the status-based mapping
    }
    return null;
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
