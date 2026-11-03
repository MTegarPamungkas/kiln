import 'package:kiln_core/kiln_core.dart';

import 'rest_token_store.dart';

/// Tokens and user fields parsed from one auth response.
final class ParsedAuthResponse {
  const ParsedAuthResponse({required this.tokens, required this.user});

  final AuthTokens tokens;
  final Map<String, Object?> user;
}

/// Parses camelCase and snake_case auth responses with varied token shapes.
final class AuthResponseParser {
  const AuthResponseParser({this.clock = const SystemClock()});

  final Clock clock;

  ParsedAuthResponse parse(Map<String, Object?> body) {
    final data = _map(body['data']) ?? body;
    final sources = <Map<String, Object?>>[
      data,
      ?_map(data['tokens']),
      ?_map(data['auth']),
      ?_map(body['tokens']),
      body,
    ];
    final accessToken = _string(sources, const <String>[
      'accessToken',
      'access_token',
      'token',
      'jwt',
    ]);
    if (accessToken == null || accessToken.isEmpty) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'Respons autentikasi tidak memuat access token.',
        kind: FailureKind.authentication,
      );
    }
    final refreshToken = _string(sources, const <String>[
      'refreshToken',
      'refresh_token',
    ]);
    final expiresAt = _expiry(sources);
    final user =
        _map(data['user']) ??
        _map(body['user']) ??
        _map(data['profile']) ??
        data;
    return ParsedAuthResponse(
      tokens: AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      ),
      user: user,
    );
  }

  DateTime? _expiry(List<Map<String, Object?>> sources) {
    for (final source in sources) {
      final expiresIn = _number(source, const <String>[
        'expiresIn',
        'expires_in',
      ]);
      if (expiresIn != null) {
        return clock.now().toUtc().add(Duration(seconds: expiresIn.round()));
      }
      final raw = _value(source, const <String>['expiresAt', 'expires_at']);
      if (raw is num) {
        final value = raw.toInt();
        final milliseconds = value > 100000000000 ? value : value * 1000;
        return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
      }
      if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) {
          return parsed.toUtc();
        }
        final epoch = int.tryParse(raw);
        if (epoch != null) {
          return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
        }
      }
    }
    return null;
  }

  Object? _value(Map<String, Object?> source, List<String> keys) {
    for (final key in keys) {
      if (source.containsKey(key)) {
        return source[key];
      }
    }
    return null;
  }

  String? _string(List<Map<String, Object?>> sources, List<String> keys) {
    for (final source in sources) {
      final value = _value(source, keys);
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  num? _number(Map<String, Object?> source, List<String> keys) {
    final value = _value(source, keys);
    if (value is num) {
      return value;
    }
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }

  Map<String, Object?>? _map(Object? value) {
    if (value is! Map) {
      return null;
    }
    return <String, Object?>{
      for (final entry in value.entries) '${entry.key}': entry.value,
    };
  }
}
