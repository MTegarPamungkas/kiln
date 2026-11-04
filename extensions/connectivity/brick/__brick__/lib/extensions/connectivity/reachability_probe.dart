import 'package:kiln_core/kiln_core.dart';

/// Checks whether a server is reachable through the HttpClient contract.
final class ReachabilityProbe {
  const ReachabilityProbe();

  Future<bool> probe(
    HttpClient? client,
    Uri uri, {
    Duration? timeout,
  }) async {
    if (client == null) {
      return true;
    }
    try {
      final future = client.send(
        HttpRequest(method: HttpMethod.head, uri: uri),
      );
      final response = timeout == null
          ? await future
          : await future.timeout(timeout);
      return response.isSuccessful;
    } catch (_) {
      return false;
    }
  }
}
