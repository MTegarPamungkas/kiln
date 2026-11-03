import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/http_cache/cache_invalidation.dart';

void main() {
  const invalidation = CacheInvalidation();
  final request = HttpRequest(
    method: HttpMethod.post,
    uri: Uri.parse('https://api.kiln.dev/users/42'),
  );

  test('detects mutations', () {
    expect(invalidation.isMutation(HttpMethod.post), isTrue);
    expect(invalidation.isMutation(HttpMethod.get), isFalse);
    expect(invalidation.isMutation(HttpMethod.head), isFalse);
  });

  test('computes a path prefix and a tag', () {
    expect(invalidation.prefixFor(request), '/users/42');
    expect(invalidation.tagsFor(request), {'users'});
  });
}
