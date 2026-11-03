import 'package:kiln_core/kiln_core.dart';

/// Decides whether a request may be replayed safely.
final class Idempotency {
  const Idempotency();

  static const String headerName = 'Idempotency-Key';

  bool isIdempotent(HttpRequest request) {
    switch (request.method) {
      case HttpMethod.get:
      case HttpMethod.head:
      case HttpMethod.put:
      case HttpMethod.delete:
        return true;
      case HttpMethod.post:
      case HttpMethod.patch:
        return request.headers.keys.any(
          (key) => key.toLowerCase() == headerName.toLowerCase(),
        );
    }
  }
}
