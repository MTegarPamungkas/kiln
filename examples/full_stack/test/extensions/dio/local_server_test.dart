import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/dio/dio_client.dart';
import 'package:full_stack/extensions/dio/dio_config.dart';

void main() {
  late io.HttpServer server;
  late Uri baseUri;

  setUp(() async {
    server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    baseUri = Uri.parse('http://127.0.0.1:${server.port}');
  });

  tearDown(() async {
    await server.close(force: true);
  });

  DioClient buildClient({
    Duration receiveTimeout = const Duration(seconds: 5),
  }) {
    return DioClient(
      config: DioConfig(
        baseUrl: baseUri.toString(),
        receiveTimeout: receiveTimeout,
      ),
    );
  }

  Future<void> sendJson(io.HttpRequest request, Object? body) async {
    request.response
      ..statusCode = 200
      ..headers.contentType = io.ContentType.json
      ..write(jsonEncode(body));
    await request.response.close();
  }

  test('401 reaches policy middleware as a response', () async {
    server.listen((request) {
      request.response
        ..statusCode = 401
        ..headers.contentType = io.ContentType.json
        ..write(jsonEncode(<String, Object?>{'message': 'expired'}));
      request.response.close();
    });

    final response = await buildClient().get(baseUri.resolve('/private'));

    expect(response.statusCode, 401);
    expect(response.isSuccessful, isFalse);
    expect(response.data, <String, Object?>{'message': 'expired'});
  });

  test('429 keeps Retry-After for retry policy', () async {
    server.listen((request) {
      request.response
        ..statusCode = 429
        ..headers.set('retry-after', '9');
      request.response.close();
    });

    final response = await buildClient().get(baseUri.resolve('/limited'));

    expect(response.statusCode, 429);
    expect(response.header('retry-after'), '9');
  });

  test('receive timeout bounds a slow response', () async {
    server.listen((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await sendJson(request, <String, Object?>{'ok': true});
    });

    await expectLater(
      buildClient(receiveTimeout: const Duration(milliseconds: 100))
          .get(baseUri.resolve('/slow')),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.networkTimeout,
        ),
      ),
    );
  });

  test('cancellation stops an in-flight request', () async {
    server.listen((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await sendJson(request, <String, Object?>{'ok': true});
    });
    final token = HttpCancelToken();
    final future = buildClient().get(
      baseUri.resolve('/slow'),
      cancelToken: token,
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
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
  });
}
