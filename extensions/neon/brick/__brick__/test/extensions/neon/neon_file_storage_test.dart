import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_file_storage.dart';

import 'test_support.dart';

void main() {
  late FakeNeonStorageGateway gateway;
  late NeonFileStorage storage;

  setUp(() {
    gateway = FakeNeonStorageGateway();
    storage = NeonFileStorage(gateway: gateway);
  });

  test('upload and download round-trip', () async {
    final uploaded = await storage.upload(
      const FileUpload(
        path: 'a/b.txt',
        bytes: <int>[1, 2, 3],
        contentType: 'text/plain',
      ),
    );

    expect(uploaded.path, 'a/b.txt');
    expect(uploaded.size, 3);
    expect(uploaded.url, contains('a/b.txt'));
    expect(await storage.download('a/b.txt'), <int>[1, 2, 3]);
  });

  test('upload with a zero lifetime is rejected before the gateway runs',
      () async {
    final broken = NeonFileStorage(
      gateway: gateway,
      signedUrlLifetime: Duration.zero,
    );

    await expectLater(
      broken.upload(const FileUpload(path: 'a.txt', bytes: <int>[1])),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
    expect(gateway.uploadedPaths, isEmpty);
  });

  test('url returns a signed link that names the file', () async {
    await storage.upload(
      const FileUpload(path: 'avatars/user-1.png', bytes: <int>[9]),
    );

    final uri = await storage.url('avatars/user-1.png');

    expect(uri.scheme, isNotEmpty);
    expect(uri.toString(), contains('user-1.png'));
  });

  test('progress reaches completion', () async {
    final progress = <double>[];

    await storage.upload(
      const FileUpload(path: 'a.txt', bytes: <int>[1]),
      onProgress: progress.add,
    );

    expect(progress, isNotEmpty);
    expect(progress.last, 1.0);
  });

  test('delete then download is fileNotFound', () async {
    await storage.upload(const FileUpload(path: 'a.txt', bytes: <int>[1]));
    await storage.delete('a.txt');

    await expectLater(
      storage.download('a.txt'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.fileNotFound,
        ),
      ),
    );
  });

  test('an unsafe path is rejected before the gateway runs', () async {
    final before = gateway.uploadedPaths.length;

    await expectLater(
      storage.download('/absolute/path'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
    expect(gateway.uploadedPaths.length, before);
  });

  test('a lifetime of zero is rejected', () {
    expect(
      () => storage.url('a.txt', expiresIn: Duration.zero),
      throwsA(isA<Failure>()),
    );
  });

  test('a gateway failure passes through mapped', () async {
    gateway.failure = const Failure(
      code: FailureCode.fileUploadFailed,
      message: 'quota',
      kind: FailureKind.storage,
    );

    await expectLater(
      storage.upload(const FileUpload(path: 'a.txt', bytes: <int>[1])),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.fileUploadFailed,
        ),
      ),
    );
  });
}
