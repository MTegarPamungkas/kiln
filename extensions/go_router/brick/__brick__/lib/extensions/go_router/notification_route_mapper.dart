import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

/// Maps a `NotificationTap` payload to a router location.
///
/// Both a plain route (`/orders/42`) and a JSON object
/// (`{"route":"/orders/42"}`) are supported. Payloads without a leading slash,
/// malformed JSON, and non-string routes are ignored.
final class NotificationRouteMapper {
  const NotificationRouteMapper();

  String? map(NotificationTap tap) => mapPayload(tap.payload);

  String? mapPayload(String? payload) {
    final raw = payload?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    if (!raw.startsWith('{')) {
      return _normalize(raw);
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    final Object? route = decoded['route'];
    return route is String ? _normalize(route) : null;
  }

  String? _normalize(String route) {
    final trimmed = route.trim();
    if (!trimmed.startsWith('/') ||
        trimmed.contains('\\') ||
        trimmed.codeUnits.any((unit) => unit < 32)) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    try {
      // Inspect the original path before Uri normalizes encoded dot segments.
      final path = Uri.decodeComponent(trimmed.split(RegExp(r'[?#]')).first);
      if (path.startsWith('//') ||
          path.contains('\\') ||
          path.codeUnits.any((unit) => unit < 32) ||
          RegExp(r'%2f|%5c', caseSensitive: false).hasMatch(path) ||
          path.split('/').any((part) => part == '.' || part == '..')) {
        return null;
      }
    } on FormatException {
      return null;
    }
    return trimmed;
  }
}
