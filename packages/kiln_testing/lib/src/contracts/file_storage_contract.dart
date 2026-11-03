import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef FileStorageContractFactory = FutureOr<FileStorage> Function();

/// Behavior every [FileStorage] implementation must share.
void fileStorageContract({
  required FileStorageContractFactory create,
  String description = 'FileStorage',
}) {
  group('$description contract', () {
    test('upload, download, link, and delete round-trip', () async {
      final storage = await create();
      const path = 'avatars/user-1.png';
      const bytes = <int>[1, 2, 3, 4];

      final uploaded = await storage.upload(
        const FileUpload(path: path, bytes: bytes, contentType: 'image/png'),
      );
      expect(uploaded.path, path);
      expect(uploaded.size, bytes.length);

      expect(await storage.download(path), bytes);

      final uri = await storage.url(path);
      expect(uri.scheme, isNotEmpty);
      expect(uri.toString(), contains('user-1.png'));

      await storage.delete(path);
      await expectLater(
        storage.download(path),
        throwsA(
          isA<Failure>().having(
            (value) => value.code,
            'code',
            FailureCode.fileNotFound,
          ),
        ),
      );
    });

    test('progress callbacks reach completion', () async {
      final storage = await create();
      final progress = <double>[];

      await storage.upload(
        const FileUpload(path: 'a.txt', bytes: [9]),
        onProgress: progress.add,
      );

      expect(progress, isNotEmpty);
      expect(progress.last, 1.0);
    });
  });
}
