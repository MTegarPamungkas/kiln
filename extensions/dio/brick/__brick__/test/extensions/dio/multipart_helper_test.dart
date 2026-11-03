import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/dio/dio_client.dart';
import 'package:{{app_name}}/extensions/dio/dio_config.dart';
import 'package:{{app_name}}/extensions/dio/dio_test_adapter.dart';
import 'package:{{app_name}}/extensions/dio/multipart_helper.dart';

void main() {
  test('uploads a multipart file', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.kiln.dev'));
    dio.httpClientAdapter = DioTestAdapter((options) async {
      captured = options;
      return ResponseBody.fromString('{}', 200);
    });
    final client = DioClient(
      dio: dio,
      config: const DioConfig(baseUrl: 'https://api.kiln.dev'),
    );

    final response = await uploadMultipart(
      client,
      path: '/upload',
      field: 'file',
      filename: 'avatar.txt',
      bytes: const [1, 2, 3],
    );

    expect(captured?.method, 'POST');
    expect(captured?.data, isA<FormData>());
    expect(response.statusCode, 200);
  });
}
