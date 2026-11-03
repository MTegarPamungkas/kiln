import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/http_cache/etag_validator.dart';

void main() {
  const validator = EtagValidator();
  final request = HttpRequest(
    method: HttpMethod.get,
    uri: Uri.parse('https://api.kiln.dev/users'),
  );

  test('reads the ETag from the cached response', () {
    final entry = CacheEntry(
      response: const HttpResponse(
        statusCode: 200,
        headers: {
          'ETag': ['v1'],
        },
      ),
      storedAt: DateTime.utc(2026, 11, 1),
    );

    expect(validator.ifNoneMatch(request, entry), 'v1');
    expect(validator.ifNoneMatch(request, null), isNull);
  });

  test('detects a 304 response', () {
    expect(
      validator.isNotModified(const HttpResponse(statusCode: 304)),
      isTrue,
    );
    expect(
      validator.isNotModified(const HttpResponse(statusCode: 200)),
      isFalse,
    );
  });
}
