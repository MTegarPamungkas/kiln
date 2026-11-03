import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

/// A typed notification payload carrying a route and its arguments.
final class NotificationPayload {
  const NotificationPayload({
    this.route,
    this.arguments = const <String, Object?>{},
  });

  static const maxEncodedLength = 4096;

  final String? route;
  final Map<String, Object?> arguments;

  String encode() {
    final encoded = jsonEncode(<String, Object?>{
      if (route != null) 'route': route,
      if (arguments.isNotEmpty) 'args': arguments,
    });
    if (encoded.length > maxEncodedLength) {
      throw Failure(
        code: FailureCode.validationInvalidInput,
        message:
            'Notification payload exceeds $maxEncodedLength characters.',
        kind: FailureKind.validation,
      );
    }
    return encoded;
  }

  /// Decodes a payload, returning null when it is absent or malformed.
  static NotificationPayload? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final route = decoded['route'];
      final arguments = decoded['args'];
      return NotificationPayload(
        route: route is String ? route : null,
        arguments: arguments is Map
            ? <String, Object?>{
                for (final entry in arguments.entries) '${entry.key}': entry.value,
              }
            : const <String, Object?>{},
      );
    } on FormatException {
      return null;
    }
  }
}
