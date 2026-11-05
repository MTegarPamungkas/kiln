import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';

void main() {
  test('returns non-2xx responses by default', () async {
    final client = FakeHttpClient(
      defaultResponse: const HttpResponse(statusCode: 404),
    );

    final response = await client.get(Uri.parse('https://api.kiln.dev'));

    expect(response.statusCode, 404);
  });

  test('throwOnError maps 404 to unavailable', () async {
    final client = FakeHttpClient(
      defaultResponse: const HttpResponse(statusCode: 404),
      throwOnError: true,
    );

    await expectLater(
      client.get(Uri.parse('https://api.kiln.dev')),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.unavailable,
        ),
      ),
    );
  });

  test('throwOnError marks 429 and 5xx as retryable', () async {
    for (final statusCode in <int>[429, 503]) {
      final client = FakeHttpClient(
        defaultResponse: HttpResponse(statusCode: statusCode),
        throwOnError: true,
      );

      await expectLater(
        client.get(Uri.parse('https://api.kiln.dev')),
        throwsA(
          isA<Failure>()
              .having((failure) => failure.code, 'code', FailureCode.networkServer)
              .having((failure) => failure.isRetryable, 'retryable', isTrue),
        ),
      );
    }
  });
}
