import 'package:kiln_core/kiln_core.dart';

/// Decides whether a request may be replayed safely.
final class Idempotency {
  const Idempotency();

  static const String headerName = 'Idempotency-Key';

  bool isIdempotent(HttpRequest request) {
    if (!isReplayable(request)) {
      return false;
    }
    switch (request.method) {
      case HttpMethod.get:
      case HttpMethod.head:
      case HttpMethod.put:
      case HttpMethod.delete:
        return true;
      case HttpMethod.post:
      case HttpMethod.patch:
        return _idempotencyKey(request) != null;
    }
  }

  /// Whether the body can be sent again unchanged.
  bool isReplayable(HttpRequest request) {
    final body = request.body;
    return body == null || body is String || body is List<int> || body is Map;
  }

  String? _idempotencyKey(HttpRequest request) {
    for (final entry in request.headers.entries) {
      if (entry.key.toLowerCase() == headerName.toLowerCase()) {
        final value = entry.value.trim();
        return value.isEmpty ? null : value;
      }
    }
    return null;
  }
}
