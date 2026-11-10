import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/http_retry/idempotency.dart';

HttpRequest _request(
  HttpMethod method, {
  Map<String, String> headers = const {},
}) {
  return HttpRequest(
    method: method,
    uri: Uri.parse('https://api.kiln.dev'),
    headers: headers,
  );
}

void main() {
  const idempotency = Idempotency();

  test('safe and idempotent methods can be retried', () {
    for (final method in <HttpMethod>[
      HttpMethod.get,
      HttpMethod.head,
      HttpMethod.put,
      HttpMethod.delete,
    ]) {
      expect(idempotency.isIdempotent(_request(method)), isTrue);
    }
  });

  test('unsafe methods need an Idempotency-Key', () {
    expect(idempotency.isIdempotent(_request(HttpMethod.post)), isFalse);
    expect(
      idempotency.isIdempotent(
        _request(HttpMethod.post, headers: const {'Idempotency-Key': 'req-1'}),
      ),
      isTrue,
    );
  });
}
