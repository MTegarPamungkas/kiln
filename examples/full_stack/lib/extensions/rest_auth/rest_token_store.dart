import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

/// Access and refresh tokens together with their expiry.
final class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

/// Stores auth tokens and the cached user in [SecureStorage].
final class RestTokenStore {
  RestTokenStore({required this.storage, this.prefix = 'rest_auth'});

  final SecureStorage storage;
  final String prefix;

  String get _accessKey => '$prefix.access_token';
  String get _refreshKey => '$prefix.refresh_token';
  String get _expiresKey => '$prefix.expires_at';
  String get _userKey => '$prefix.user';

  Future<AuthTokens?> read() async {
    final accessToken = await storage.read(_accessKey);
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }
    final refreshToken = await storage.read(_refreshKey);
    final expiresRaw = await storage.read(_expiresKey);
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresRaw == null ? null : DateTime.tryParse(expiresRaw),
    );
  }

  Future<void> save(AuthTokens tokens) async {
    await storage.write(_accessKey, tokens.accessToken);
    final refreshToken = tokens.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await storage.write(_refreshKey, refreshToken);
    } else {
      await storage.delete(_refreshKey);
    }
    final expiresAt = tokens.expiresAt;
    if (expiresAt != null) {
      await storage.write(_expiresKey, expiresAt.toUtc().toIso8601String());
    } else {
      await storage.delete(_expiresKey);
    }
  }

  Future<String?> refreshToken() => storage.read(_refreshKey);

  Future<Map<String, Object?>?> readUser() async {
    final raw = await storage.read(_userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return <String, Object?>{
        for (final entry in decoded.entries) '${entry.key}': entry.value,
      };
    } on FormatException {
      return null;
    }
  }

  Future<void> saveUser(Map<String, Object?> user) {
    return storage.write(_userKey, jsonEncode(user));
  }

  Future<void> clear() async {
    await Future.wait(<Future<void>>[
      storage.delete(_accessKey),
      storage.delete(_refreshKey),
      storage.delete(_expiresKey),
      storage.delete(_userKey),
    ]);
  }
}
