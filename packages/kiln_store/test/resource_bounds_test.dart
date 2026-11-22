import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kiln_store/kiln_store.dart';
import 'package:test/test.dart';

final class _StreamingClient extends http.BaseClient {
  _StreamingClient(this.response);
  final http.StreamedResponse response;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      response;
}

void main() {
  test(
    'inflated gzip data is bounded before tar parsing and file writes',
    () async {
      final root = await Directory.systemTemp.createTemp('kiln_inflate_bound_');
      final target = Directory('${root.path}/extract');
      try {
        final compressed = gzip.encode(List<int>.filled(200000, 0));
        expect(compressed.length, lessThan(4096));
        expect(
          () => const ArchiveUnpacker(
            maxCompressedBytes: 4096,
            maxExpandedBytes: 64,
            maxEntries: 2,
          ).extract(compressed, target),
          throwsA(
            isA<KilnStoreException>().having(
              (error) => error.code,
              'code',
              'store.archive_too_large',
            ),
          ),
        );
        expect(target.existsSync(), isFalse);
      } finally {
        await root.delete(recursive: true);
      }
    },
  );

  test('oversized chunked download stops consuming the body', () async {
    var chunksRead = 0;
    var cancelled = false;
    Stream<List<int>> body() async* {
      try {
        for (var index = 0; index < 100; index++) {
          chunksRead++;
          yield [1, 2, 3, 4];
        }
      } finally {
        cancelled = true;
      }
    }

    final client = RegistryClient(
      config: RegistryConfig(url: 'https://example.com/registry'),
      httpClient: _StreamingClient(http.StreamedResponse(body(), 200)),
      maxDownloadBytes: 5,
    );
    await expectLater(
      client.fetchIndex(),
      throwsA(
        isA<KilnStoreException>().having(
          (error) => error.code,
          'code',
          'store.fetch_failed',
        ),
      ),
    );
    expect(chunksRead, 2);
    expect(cancelled, isTrue);
  });

  test('local registry files use the same download size bound', () async {
    final root = await Directory.systemTemp.createTemp('kiln_file_bound_');
    try {
      await File('${root.path}/index.json').writeAsString(' ' * 100);
      final client = RegistryClient(
        config: RegistryConfig(url: root.path),
        maxDownloadBytes: 5,
      );
      try {
        await expectLater(
          client.fetchIndex(),
          throwsA(
            isA<KilnStoreException>().having(
              (error) => error.code,
              'code',
              'store.fetch_failed',
            ),
          ),
        );
      } finally {
        client.close();
      }
    } finally {
      await root.delete(recursive: true);
    }
  });
}
