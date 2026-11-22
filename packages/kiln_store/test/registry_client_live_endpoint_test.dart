import 'dart:async';
import 'dart:io';

import 'package:kiln_store/kiln_store.dart';
import 'package:test/test.dart';

/// Starts a loopback server whose handler runs for every request.
Future<HttpServer> _start(FutureOr<void> Function(HttpRequest) handler) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    try {
      await handler(request);
    } on Object {
      // A client that stops reading mid-body resets the response; expected.
    }
  });
  return server;
}

RegistryClient _client(HttpServer server, {Duration? timeout, int? maxBytes}) {
  return RegistryClient(
    config: RegistryConfig(url: 'http://127.0.0.1:${server.port}'),
    requestTimeout: timeout ?? const Duration(seconds: 5),
    maxDownloadBytes: maxBytes ?? 4 * 1024 * 1024,
  );
}

Matcher _fetchFailure() => throwsA(
  isA<KilnStoreException>().having(
    (error) => error.code,
    'code',
    'store.fetch_failed',
  ),
);

void main() {
  test('a slow live endpoint fails with an actionable timeout', () async {
    final server = await _start((request) async {
      await Future<void>.delayed(const Duration(seconds: 2));
      request.response.write('{}');
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final client = _client(server, timeout: const Duration(milliseconds: 200));
    addTearDown(client.close);

    final stopwatch = Stopwatch()..start();
    await expectLater(client.fetchIndex(), _fetchFailure());
    stopwatch.stop();
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('an oversized live body is cut off at the byte budget', () async {
    final server = await _start((request) async {
      request.response.headers.contentType = ContentType.json;
      final chunk = List<int>.filled(64 * 1024, 0x20);
      for (var index = 0; index < 64; index++) {
        request.response.add(chunk);
        await request.response.flush();
      }
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final client = _client(server, maxBytes: 64 * 1024);
    addTearDown(client.close);

    await expectLater(client.fetchIndex(), _fetchFailure());
  });

  test('a valid live index still parses within the default budget', () async {
    const body =
        '{"schema_version": 1, '
        '"generated_at": "2026-11-22T00:00:00Z", '
        '"extensions": []}';
    final server = await _start((request) async {
      request.response.headers.contentType = ContentType.json;
      request.response.write(body);
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final client = _client(server);
    addTearDown(client.close);

    final index = await client.fetchIndex();
    expect(index.extensions, isEmpty);
  });
}
