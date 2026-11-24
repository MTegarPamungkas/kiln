import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/dio/dio_client.dart';
import 'package:full_stack/extensions/dio/dio_config.dart';
import 'package:full_stack/extensions/dio/dio_test_adapter.dart';

final class _ClosingAdapter implements HttpClientAdapter {
  int closeCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('{}', 200);

  @override
  void close({bool force = false}) {
    closeCalls++;
  }
}

void main() {
  test('sends a GET request and decodes JSON', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.kiln.dev'));
    dio.httpClientAdapter = DioTestAdapter((options) async {
      captured = options;
      return ResponseBody.fromString(
        jsonEncode({'ok': true}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final client = DioClient(
      dio: dio,
      config: const DioConfig(baseUrl: 'https://api.kiln.dev'),
    );

    final response = await client.get(Uri.parse('https://api.kiln.dev/users'));

    expect(captured?.method, 'GET');
    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});
  });

  test('resolves relative paths against the configured base URL', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.kiln.dev/v1'));
    dio.httpClientAdapter = DioTestAdapter((options) async {
      captured = options;
      return ResponseBody.fromString(
        jsonEncode({'ok': true}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final client = DioClient(
      dio: dio,
      config: const DioConfig(baseUrl: 'https://api.kiln.dev/v1'),
    );

    final response = await client.get(Uri.parse('/users'));

    expect(captured?.uri.toString(), 'https://api.kiln.dev/v1/users');
    expect(response.requestUri?.toString(), 'https://api.kiln.dev/v1/users');
  });

  test('adds the API key as a query parameter', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.kiln.dev'));
    dio.httpClientAdapter = DioTestAdapter((options) async {
      captured = options;
      return ResponseBody.fromString(
        jsonEncode({'ok': true}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final client = DioClient(
      dio: dio,
      config: const DioConfig(
        baseUrl: 'https://api.kiln.dev',
        apiKey: 'secret-key',
        apiKeyQueryParameter: 'key',
      ),
    );

    await client.get(Uri.parse('/users'));

    expect(captured?.uri.queryParameters['key'], 'secret-key');
  });

  test('adds the API key as a header with its prefix', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.kiln.dev'));
    dio.httpClientAdapter = DioTestAdapter((options) async {
      captured = options;
      return ResponseBody.fromString(
        jsonEncode({'ok': true}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final client = DioClient(
      dio: dio,
      config: const DioConfig(
        baseUrl: 'https://api.kiln.dev',
        apiKey: 'secret-key',
        apiKeyHeader: 'X-Api-Key',
        apiKeyPrefix: 'Bearer ',
      ),
    );

    await client.get(Uri.parse('/users'));

    expect(captured?.headers['X-Api-Key'], 'Bearer secret-key');
    expect(captured?.uri.queryParameters['key'], isNull);
  });

  test('never sends the API key to another origin', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.kiln.dev'));
    dio.httpClientAdapter = DioTestAdapter((options) async {
      captured = options;
      return ResponseBody.fromString(
        jsonEncode({'ok': true}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final client = DioClient(
      dio: dio,
      config: const DioConfig(
        baseUrl: 'https://api.kiln.dev',
        apiKey: 'secret-key',
        apiKeyHeader: 'X-Api-Key',
      ),
    );

    await client.get(Uri.parse('https://cdn.third-party.test/file'));

    expect(captured?.headers.containsKey('X-Api-Key'), isFalse);
    expect(captured?.uri.queryParameters['key'], isNull);
  });

  test('returns 304 so cache middleware can revalidate', () async {
    final dio = Dio();
    dio.httpClientAdapter = DioTestAdapter(
      (_) async => ResponseBody.fromString('', 304),
    );
    final client = DioClient(dio: dio);

    final response = await client.get(
      Uri.parse('https://api.kiln.dev/users'),
      headers: const <String, String>{'If-None-Match': 'W/"v1"'},
    );

    expect(response.statusCode, 304);
    expect(response.isSuccessful, isFalse);
  });

  test('returns HTTP error responses to policy middleware', () async {
    final dio = Dio();
    dio.httpClientAdapter = DioTestAdapter(
      (_) async => ResponseBody.fromString(
        jsonEncode({'message': 'expired'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    final client = DioClient(dio: dio);

    final response = await client.get(
      Uri.parse('https://api.kiln.dev/users'),
    );

    expect(response.statusCode, 401);
    expect(response.isSuccessful, isFalse);
    expect(response.data, {'message': 'expired'});
  });

  test('keeps Retry-After headers on rejected responses', () async {
    final dio = Dio();
    dio.httpClientAdapter = DioTestAdapter(
      (_) async => ResponseBody.fromString(
        '{}',
        429,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'retry-after': ['9'],
        },
      ),
    );
    final client = DioClient(dio: dio);

    final response = await client.get(
      Uri.parse('https://api.kiln.dev/users'),
    );

    expect(response.statusCode, 429);
    expect(response.header('retry-after'), '9');
  });

  test('maps transport failures to Failure', () async {
    final dio = Dio();
    dio.httpClientAdapter = DioTestAdapter(
      (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
    final client = DioClient(dio: dio);

    await expectLater(
      client.get(Uri.parse('https://api.kiln.dev/users')),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.networkUnreachable,
        ),
      ),
    );
  });

  test('applies configured timeouts to the transport request', () async {
    RequestOptions? captured;
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.kiln.dev',
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 9),
      ),
    );
    dio.httpClientAdapter = DioTestAdapter((options) async {
      captured = options;
      return ResponseBody.fromString(
        '{}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final client = DioClient(
      dio: dio,
      config: const DioConfig(
        baseUrl: 'https://api.kiln.dev',
        connectTimeout: Duration(seconds: 3),
        receiveTimeout: Duration(seconds: 9),
      ),
    );

    await client.get(Uri.parse('https://api.kiln.dev/users'));

    expect(captured?.connectTimeout, const Duration(seconds: 3));
    expect(captured?.receiveTimeout, const Duration(seconds: 9));
  });

  test('an expired request deadline fails before the transport', () async {
    var sends = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.kiln.dev'));
    dio.httpClientAdapter = DioTestAdapter((_) async {
      sends++;
      return ResponseBody.fromString('{}', 200);
    });
    final clock = FixedClock(DateTime.utc(2026, 11, 21));
    final client = DioClient(dio: dio, clock: clock);

    await expectLater(
      client.send(
        HttpRequest(
          method: HttpMethod.get,
          uri: Uri.parse('https://api.kiln.dev/users'),
          deadline: clock.now().subtract(const Duration(seconds: 1)),
        ),
      ),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.networkDeadlineExceeded,
        ),
      ),
    );
    expect(sends, 0);
  });

  test('cancels the transport when the deadline passes', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.kiln.dev'));
    dio.httpClientAdapter = DioTestAdapter((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return ResponseBody.fromString('{}', 200);
    });
    final client = DioClient(dio: dio);

    await expectLater(
      client.send(
        HttpRequest(
          method: HttpMethod.get,
          uri: Uri.parse('https://api.kiln.dev/users'),
          deadline: DateTime.now().add(const Duration(milliseconds: 100)),
        ),
      ),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.networkDeadlineExceeded,
        ),
      ),
    );
  });

  test('clamps transport timeouts to the deadline', () async {
    RequestOptions? captured;
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.kiln.dev',
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 9),
      ),
    );
    dio.httpClientAdapter = DioTestAdapter((options) async {
      captured = options;
      return ResponseBody.fromString(
        '{}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final client = DioClient(
      dio: dio,
      config: const DioConfig(
        baseUrl: 'https://api.kiln.dev',
        connectTimeout: Duration(seconds: 3),
        receiveTimeout: Duration(seconds: 9),
      ),
    );

    await client.send(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev/users'),
        deadline: DateTime.now().add(const Duration(milliseconds: 500)),
      ),
    );

    expect(captured, isNotNull);
    expect(
      captured!.receiveTimeout,
      lessThanOrEqualTo(const Duration(milliseconds: 500)),
    );
    expect(
      captured!.sendTimeout,
      lessThanOrEqualTo(const Duration(milliseconds: 500)),
    );
  });

  test('closes only a transport it created', () {
    final adapter = _ClosingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final injected = DioClient(dio: dio);

    injected.close(force: true);
    expect(adapter.closeCalls, 0);

    final owned = DioClient(
      config: const DioConfig(baseUrl: 'https://api.kiln.dev'),
    );
    owned.close(force: true);
  });

  test('cancelling the token aborts an in-flight request', () async {
    final dio = Dio();
    final pending = Completer<void>();
    dio.httpClientAdapter = DioTestAdapter((options) async {
      await pending.future;
      return ResponseBody.fromString('{}', 200);
    });
    final client = DioClient(dio: dio);
    final token = HttpCancelToken();

    final future = client.get(
      Uri.parse('https://api.kiln.dev/slow'),
      cancelToken: token,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    token.cancel();

    await expectLater(
      future,
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.cancelled,
        ),
      ),
    );
    pending.complete();
  });
}
