import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/dio/dio_client.dart';
import 'package:full_stack/extensions/dio/dio_config.dart';
import 'package:full_stack/extensions/dio/dio_test_adapter.dart';
import 'package:full_stack/extensions/dio/download_helper.dart';

void main() {
  test('downloads a file to disk', () async {
    final temp = await Directory.systemTemp.createTemp('kiln_download_');
    final savePath = '${temp.path}/file.txt';
    final dio = Dio(BaseOptions(baseUrl: 'https://api.kiln.dev'));
    dio.httpClientAdapter = DioTestAdapter(
      (_) async => ResponseBody.fromBytes(
        utf8.encode('downloaded'),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/octet-stream'],
        },
      ),
    );
    final client = DioClient(
      dio: dio,
      config: const DioConfig(baseUrl: 'https://api.kiln.dev'),
    );

    try {
      await downloadFile(client, path: '/file.txt', savePath: savePath);
      expect(File(savePath).readAsStringSync(), 'downloaded');
    } finally {
      await temp.delete(recursive: true);
    }
  });
}
