import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/dio/dio_client.dart';
import 'package:full_stack/extensions/dio/dio_config.dart';
import 'package:full_stack/extensions/dio/dio_test_adapter.dart';

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

    final response = await client.get(
      Uri.parse('https://api.kiln.dev/users'),
    );

    expect(captured?.method, 'GET');
    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});
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
