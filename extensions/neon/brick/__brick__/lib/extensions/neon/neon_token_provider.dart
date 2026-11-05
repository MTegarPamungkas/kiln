// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kiln_core/kiln_core.dart';

import 'neon_gateway.dart';

/// Supplies the bearer token sent on Data API requests.
///
/// Two sources exist: a fixed token from configuration, or the short-lived
/// anonymous JWT minted by Neon Auth. The latter lets `remote_database` work
/// with zero token plumbing once the `anonymous` role has table grants.
abstract interface class NeonTokenProvider {
  Future<String?> token();
}

/// Uses a fixed bearer token from configuration.
final class StaticNeonTokenProvider implements NeonTokenProvider {
  StaticNeonTokenProvider(String token) : _token = token;

  final String _token;

  @override
  Future<String?> token() async => _token;
}

/// Fetches and caches the anonymous JWT from Neon Auth
/// (`{authUrl}/token/anonymous`), reusing it until a minute before its `exp`
/// claim.
final class NeonAnonymousTokenProvider implements NeonTokenProvider {
  NeonAnonymousTokenProvider({
    required this.authUrl,
    http.Client? client,
    this.clock = const SystemClock(),
  }) : _client = client ?? http.Client();

  final String authUrl;
  final http.Client _client;
  final Clock clock;

  String? _token;
  DateTime? _expires;

  @override
  Future<String?> token() async {
    final cached = _token;
    final expires = _expires;
    if (cached != null &&
        expires != null &&
        expires.isAfter(clock.now().add(const Duration(minutes: 1)))) {
      return cached;
    }
    final response = await _client.get(
      Uri.parse('$authUrl/token/anonymous'),
      headers: <String, String>{'origin': _origin(authUrl)},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NeonApiException(
        'Could not fetch an anonymous Neon token.',
        statusCode: response.statusCode,
      );
    }
    final body = jsonDecode(response.body) as Map<String, Object?>;
    final token = body['token'] as String?;
    if (token == null) {
      throw const NeonApiException('The anonymous token response had no token.');
    }
    _token = token;
    _expires = _expiry(token);
    return token;
  }

  void close() => _client.close();

  static String _origin(String url) {
    final uri = Uri.tryParse(url);
    return uri == null ? '' : '${uri.scheme}://${uri.host}';
  }

  static DateTime? _expiry(String token) {
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
      // Fall through: the provider will re-fetch on the next request.
    }
    return null;
  }
}
