import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

final class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.handler);

  final Future<HttpResponse> Function(HttpRequest request) handler;

  @override
  Future<HttpResponse> send(HttpRequest request) => handler(request);

  @override
  Future<HttpResponse> get(
    Uri uri, {
    Map<String, String> headers = const {},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => send(
    HttpRequest(
      method: HttpMethod.get,
      uri: uri,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  @override
  Future<HttpResponse> post(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => send(
    HttpRequest(
      method: HttpMethod.post,
      uri: uri,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  @override
  Future<HttpResponse> put(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => send(
    HttpRequest(
      method: HttpMethod.put,
      uri: uri,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  @override
  Future<HttpResponse> patch(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => send(
    HttpRequest(
      method: HttpMethod.patch,
      uri: uri,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  @override
  Future<HttpResponse> delete(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => send(
    HttpRequest(
      method: HttpMethod.delete,
      uri: uri,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );
}

final class _RecordingMiddleware implements HttpMiddleware {
  _RecordingMiddleware(this.name, this.events);

  final String name;
  final List<String> events;

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) async {
    events.add('$name:before');
    final response = await next(request);
    events.add('$name:after');
    return response;
  }
}

void main() {
  group('HttpRequest', () {
    test('merges query parameters into the URI', () {
      final request = HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev/users?page=1'),
        queryParameters: {
          'limit': 20,
          'tags': ['a', 'b'],
          'enabled': true,
        },
      );

      expect(request.resolvedUri.queryParameters['page'], '1');
      expect(request.resolvedUri.queryParameters['limit'], '20');
      expect(request.resolvedUri.queryParametersAll['tags'], ['a', 'b']);
      expect(request.resolvedUri.queryParameters['enabled'], 'true');
    });

    test('without query parameters returns the original URI', () {
      final uri = Uri.parse('https://api.kiln.dev');
      final request = HttpRequest(method: HttpMethod.get, uri: uri);

      expect(request.resolvedUri, uri);
    });
  });

  group('HttpResponse', () {
    test('reports success and reads headers case-insensitively', () {
      const response = HttpResponse(
        statusCode: 201,
        headers: {
          'Content-Type': ['application/json'],
        },
      );

      expect(response.isSuccessful, isTrue);
      expect(response.header('content-type'), 'application/json');
      expect(response.header('missing'), isNull);
      expect(const HttpResponse(statusCode: 500).isSuccessful, isFalse);
    });
  });

  group('HttpCancelToken', () {
    test('throws a cancelled Failure after cancellation', () {
      final token = HttpCancelToken();
      token.throwIfCancelled();

      token.cancel();

      expect(token.isCancelled, isTrue);
      expect(
        token.throwIfCancelled,
        throwsA(
          isA<Failure>()
              .having((failure) => failure.code, 'code', FailureCode.cancelled)
              .having((failure) => failure.isCancelled, 'isCancelled', isTrue),
        ),
      );
    });

    test('notifies listeners once and supports removal', () {
      final token = HttpCancelToken();
      var calls = 0;
      final remove = token.onCancel(() => calls++);

      token.cancel();
      token.cancel();
      remove();
      token.cancel();

      expect(calls, 1);
    });

    test('an already cancelled token notifies immediately', () {
      final token = HttpCancelToken()..cancel();
      var calls = 0;

      token.onCancel(() => calls++);

      expect(calls, 1);
    });
  });

  group('HttpPipeline', () {
    test('executes middleware outside-in', () async {
      final events = <String>[];
      final pipeline = HttpPipeline([
        _RecordingMiddleware('outer', events),
        _RecordingMiddleware('inner', events),
      ]);

      final response = await pipeline.execute(
        HttpRequest(
          method: HttpMethod.get,
          uri: Uri.parse('https://api.kiln.dev'),
        ),
        (request) async {
          events.add('terminal:${request.method.name}');
          return const HttpResponse(statusCode: 200, data: 'ok');
        },
      );

      expect(response.data, 'ok');
      expect(events, [
        'outer:before',
        'inner:before',
        'terminal:get',
        'inner:after',
        'outer:after',
      ]);
    });

    test('orders middleware by priority before insertion order', () async {
      final events = <String>[];
      final pipeline = HttpPipeline()
        ..use(_RecordingMiddleware('last', events), priority: 30)
        ..use(_RecordingMiddleware('first', events), priority: 5)
        ..use(_RecordingMiddleware('middle', events), priority: 20);

      await pipeline.execute(
        HttpRequest(
          method: HttpMethod.get,
          uri: Uri.parse('https://api.kiln.dev'),
        ),
        (_) async => const HttpResponse(statusCode: 200),
      );

      expect(pipeline.middleware, hasLength(3));
      expect(events, [
        'first:before',
        'middle:before',
        'last:before',
        'last:after',
        'middle:after',
        'first:after',
      ]);
    });

    test('use appends middleware and useAll adds several', () async {
      final events = <String>[];
      final pipeline = HttpPipeline()
        ..use(_RecordingMiddleware('one', events))
        ..useAll([
          _RecordingMiddleware('two', events),
          _RecordingMiddleware('three', events),
        ]);

      await pipeline.execute(
        HttpRequest(
          method: HttpMethod.get,
          uri: Uri.parse('https://api.kiln.dev'),
        ),
        (_) async => const HttpResponse(statusCode: 204),
      );

      expect(pipeline.middleware.length, 3);
      expect(events.first, 'one:before');
      expect(events[2], 'three:before');
    });
  });

  group('HttpClient', () {
    test('convenience methods build the right request', () async {
      final requests = <HttpRequest>[];
      final client = _FakeHttpClient((request) async {
        requests.add(request);
        return const HttpResponse(statusCode: 200);
      });

      await client.get(Uri.parse('https://api.kiln.dev/a'));
      await client.post(Uri.parse('https://api.kiln.dev/a'), body: 'x');
      await client.put(Uri.parse('https://api.kiln.dev/a'), body: 'x');
      await client.patch(Uri.parse('https://api.kiln.dev/a'), body: 'x');
      await client.delete(Uri.parse('https://api.kiln.dev/a'));

      expect(requests.map((request) => request.method), [
        HttpMethod.get,
        HttpMethod.post,
        HttpMethod.put,
        HttpMethod.patch,
        HttpMethod.delete,
      ]);
    });

    test('network errors surface as Failure', () async {
      final client = _FakeHttpClient(
        (_) async => throw const Failure(
          code: FailureCode.networkUnreachable,
          message: 'No route to host',
          kind: FailureKind.network,
          isRetryable: true,
        ),
      );

      await expectLater(
        client.get(Uri.parse('https://api.kiln.dev')),
        throwsA(
          isA<Failure>().having(
            (failure) => failure.isRetryable,
            'isRetryable',
            isTrue,
          ),
        ),
      );
    });
  });

  group('HttpRequest deadline', () {
    final now = DateTime.utc(2026, 11, 21, 12);
    final uri = Uri.parse('https://api.kiln.dev/items');

    test('reports the remaining time and expiring state', () {
      final request = HttpRequest(
        method: HttpMethod.get,
        uri: uri,
        deadline: now.add(const Duration(seconds: 5)),
      );

      expect(request.remainingUntil(now), const Duration(seconds: 5));
      expect(request.isDeadlineExceeded(now), isFalse);
      expect(
        request.isDeadlineExceeded(now.add(const Duration(seconds: 5))),
        isTrue,
      );
      expect(
        request.remainingUntil(now.add(const Duration(seconds: 6))),
        Duration.zero,
      );
    });

    test('no deadline means unbounded and never expired', () {
      final request = HttpRequest(method: HttpMethod.get, uri: uri);

      expect(request.remainingUntil(now), isNull);
      expect(request.isDeadlineExceeded(now), isFalse);
      request.throwIfDeadlineExceeded(now);
    });

    test('throws a typed deadline failure once expired', () {
      final request = HttpRequest(
        method: HttpMethod.get,
        uri: uri,
        deadline: now.subtract(const Duration(milliseconds: 1)),
      );

      expect(
        () => request.throwIfDeadlineExceeded(now),
        throwsA(
          isA<Failure>()
              .having(
                (failure) => failure.code,
                'code',
                FailureCode.networkDeadlineExceeded,
              )
              .having(
                (failure) => failure.kind,
                'kind',
                FailureKind.network,
              ),
        ),
      );
    });

    test('copyWith keeps or replaces the deadline', () {
      final deadline = now.add(const Duration(seconds: 2));
      final request = HttpRequest(
        method: HttpMethod.get,
        uri: uri,
        deadline: deadline,
      );

      expect(request.copyWith(headers: const <String, String>{}).deadline, deadline);
      expect(
        request
            .copyWith(deadline: now.add(const Duration(seconds: 4)))
            .deadline,
        now.add(const Duration(seconds: 4)),
      );
    });
  });
}
