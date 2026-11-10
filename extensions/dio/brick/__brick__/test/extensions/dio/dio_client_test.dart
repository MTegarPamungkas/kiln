import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/dio/dio_client.dart';
import 'package:{{app_name}}/extensions/dio/dio_config.dart';
import 'package:{{app_name}}/extensions/dio/dio_test_adapter.dart';

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

  test('maps adapter failures to Failure', () async {
    final dio = Dio();
    dio.httpClientAdapter = DioTestAdapter(
      (_) async => ResponseBody.fromString('{}', 500),
    );
    final client = DioClient(dio: dio);

    await expectLater(
      client.get(Uri.parse('https://api.kiln.dev/users')),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.networkServer,
        ),
      ),
    );
  });
}
