import 'package:kiln_core/kiln_core.dart';

/// Checks whether a server is reachable through the HttpClient contract.
final class ReachabilityProbe {
  const ReachabilityProbe();

  Future<bool> probe(HttpClient? client, Uri uri) async {
    if (client == null) {
      return true;
    }
    try {
      final response = await client.send(
        HttpRequest(method: HttpMethod.head, uri: uri),
      );
      return response.isSuccessful;
    } catch (_) {
      return false;
    }
  }
}
