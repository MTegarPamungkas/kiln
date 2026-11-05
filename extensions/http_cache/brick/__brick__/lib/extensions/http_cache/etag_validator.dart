import 'package:kiln_core/kiln_core.dart';

/// Reads and checks ETag validators.
final class EtagValidator {
  const EtagValidator();

  String? ifNoneMatch(HttpRequest request, CacheEntry? entry) {
    if (entry == null) {
      return null;
    }
    return entry.response.header('ETag');
  }

  bool isNotModified(HttpResponse response) => response.statusCode == 304;
}
