import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/extensions/dio/dio_client.dart';
import 'package:full_stack/extensions/dio/dio_config.dart';
import 'package:full_stack/extensions/dio/dio_test_adapter.dart';

void main() {
  httpClientContract(
    description: 'DioClient',
    build: (responder) {
      final dio = Dio();
      dio.httpClientAdapter = DioTestAdapter((options) async {
        final request = HttpRequest(
          method: HttpMethod.values.byName(options.method.toLowerCase()),
          uri: Uri.parse(options.uri.toString()),
          headers: options.headers.map((key, value) => MapEntry(key, '$value')),
          body: options.data,
        );
        final response = await responder(request);
        final headers = <String, List<String>>{
          ...response.headers,
          if (!response.headers.keys.any(
            (key) => key.toLowerCase() == Headers.contentTypeHeader,
          ))
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        };
        return ResponseBody.fromString(
          jsonEncode(response.data),
          response.statusCode,
          headers: headers,
        );
      });
      return DioClient(
        dio: dio,
        config: const DioConfig(baseUrl: 'https://api.kiln.dev'),
      );
    },
  );
}
