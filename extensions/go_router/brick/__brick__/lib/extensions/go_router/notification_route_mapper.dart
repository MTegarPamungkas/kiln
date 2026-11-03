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
    if (!trimmed.startsWith('/')) {
      return null;
    }
    return trimmed;
  }
}
