import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

/// Reads JWT claims without verifying the signature.
final class JwtExpiry {
  const JwtExpiry._();

  static DateTime? expiryOf(String token) {
    final claims = _claims(token);
    final exp = claims?['exp'];
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );
    }
    return null;
  }

  static String? subjectOf(String token) {
    final claims = _claims(token);
    for (final key in const <String>['sub', 'user_id', 'uid']) {
      final value = claims?[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static bool isExpired(
    String token,
    Clock clock, {
    Duration leeway = const Duration(seconds: 30),
  }) {
    final expiry = expiryOf(token);
    if (expiry == null) {
      return false;
    }
    return !expiry.isAfter(clock.now().add(leeway));
  }

  static Map<String, Object?>? _claims(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (decoded is! Map) {
        return null;
      }
      return <String, Object?>{
        for (final entry in decoded.entries) '${entry.key}': entry.value,
      };
    } on Object {
      return null;
    }
  }
}
