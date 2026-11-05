import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';

import 'test_support.dart';

void main() {
  test('upload, download, link, and delete a file', () async {
    final gateway = FakeAppwriteStorageGateway();
    final storage = createFakeFileStorage(gateway: gateway);
    const file = FileUpload(
      path: 'avatars/user-1.png',
      bytes: <int>[1, 2, 3, 4],
      contentType: 'image/png',
    );

    final stored = await storage.upload(file);

    expect(stored.path, file.path);
    expect(stored.size, 4);
    expect(await storage.download(file.path), <int>[1, 2, 3, 4]);
    expect((await storage.url(file.path)).toString(), contains('user-1.png'));

    await storage.delete(file.path);
    await expectLater(
      storage.download(file.path),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.fileNotFound,
        ),
      ),
    );
  });

  test('upload progress reaches completion', () async {
    final storage = createFakeFileStorage();
    final progress = <double>[];

    await storage.upload(
      const FileUpload(path: 'a.txt', bytes: <int>[9]),
      onProgress: progress.add,
    );

    expect(progress, isNotEmpty);
    expect(progress.last, 1);
  });

  test('an empty path is rejected before the bucket call', () async {
    final gateway = FakeAppwriteStorageGateway();
    final storage = createFakeFileStorage(gateway: gateway);

    await expectLater(
      storage.download('  '),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
    expect(gateway.calls, isEmpty);
  });

  test('rate limits stay retryable', () async {
    final gateway = FakeAppwriteStorageGateway()
      ..failure = AppwriteException('Too many requests', 429);
    final storage = createFakeFileStorage(gateway: gateway);

    await expectLater(
      storage.upload(const FileUpload(path: 'a.txt', bytes: <int>[1])),
      throwsA(
        isA<Failure>()
            .having(
              (failure) => failure.code,
              'code',
              FailureCode.networkServer,
            )
            .having((failure) => failure.isRetryable, 'isRetryable', isTrue),
      ),
    );
  });
}
