import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

/// Builds a client whose transport is replaced by [responder].
typedef HttpClientContractBuilder = HttpClient Function(
  Future<HttpResponse> Function(HttpRequest) responder,
);

/// Behavior every [HttpClient] implementation must share.
void httpClientContract({
  required HttpClientContractBuilder build,
  String description = 'HttpClient',
  Uri? baseUri,
}) {
  final base = baseUri ?? Uri.parse('https://api.kiln.dev');

  group('$description contract', () {
    test(
      'GET sends a GET request and returns the transport response',
      () async {
        final requests = <HttpRequest>[];
        final client = build((request) async {
          requests.add(request);
          return const HttpResponse(statusCode: 200, data: {'ok': true});
        });

        final response = await client.get(base.resolve('/users'));

        expect(requests, hasLength(1));
        expect(requests.single.method, HttpMethod.get);
        expect(requests.single.uri.path, '/users');
        expect(response.statusCode, 200);
        expect(response.isSuccessful, isTrue);
        expect(response.data, {'ok': true});
      },
    );

    test('POST carries headers and body to the transport', () async {
      final requests = <HttpRequest>[];
      final client = build((request) async {
        requests.add(request);
        return const HttpResponse(statusCode: 201, data: 'created');
      });

      await client.post(
        base.resolve('/users'),
        body: {'name': 'Tegar'},
        headers: const {'X-Request-Id': 'req-1'},
      );

      expect(requests.single.method, HttpMethod.post);
      expect(requests.single.headers['X-Request-Id'], 'req-1');
      expect(requests.single.body, {'name': 'Tegar'});
    });

    test('query parameters are preserved', () async {
      final requests = <HttpRequest>[];
      final client = build((request) async {
        requests.add(request);
        return const HttpResponse(statusCode: 200);
      });

      await client.get(
        base.resolve('/users'),
        queryParameters: const {'page': 2, 'limit': 10},
      );

      final resolved = requests.single.resolvedUri;
      expect(resolved.queryParameters['page'], '2');
      expect(resolved.queryParameters['limit'], '10');
    });

    test('transport failures surface as Failure', () async {
      const failure = Failure(
        code: FailureCode.networkUnreachable,
        message: 'No route to host',
        kind: FailureKind.network,
        isRetryable: true,
      );
      final client = build((_) async => throw failure);

      await expectLater(
        client.get(base.resolve('/users')),
        throwsA(
          isA<Failure>()
              .having(
                (value) => value.code,
                'code',
                FailureCode.networkUnreachable,
              )
              .having((value) => value.isRetryable, 'isRetryable', isTrue),
        ),
      );
    });

    test('a cancelled token prevents the transport call', () async {
      final requests = <HttpRequest>[];
      final client = build((request) async {
        requests.add(request);
        return const HttpResponse(statusCode: 200);
      });
      final token = HttpCancelToken()..cancel();

      await expectLater(
        client.get(base.resolve('/users'), cancelToken: token),
        throwsA(
          isA<Failure>().having(
            (value) => value.code,
            'code',
            FailureCode.cancelled,
          ),
        ),
      );
      expect(requests, isEmpty);
    });
  });
}
