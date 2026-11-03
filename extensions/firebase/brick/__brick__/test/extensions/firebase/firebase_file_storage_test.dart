import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_file_storage.dart';

import 'firebase_contract_test.dart';

void main() {
  test('upload reports progress up to completion', () async {
    final gateway = InMemoryFirebaseStorageGateway();
    final storage = FirebaseFileStorage(gateway: gateway);
    final progress = <double>[];

    final uploaded = await storage.upload(
      const FileUpload(
        path: 'avatars/user-1.png',
        bytes: [1, 2, 3],
        contentType: 'image/png',
      ),
      onProgress: progress.add,
    );

    expect(uploaded.path, 'avatars/user-1.png');
    expect(uploaded.size, 3);
    expect(uploaded.url, isNotNull);
    expect(progress, isNotEmpty);
    expect(progress.last, 1);
    expect(gateway.files['avatars/user-1.png'], [1, 2, 3]);
  });

  test('download returns bytes and notifies completion', () async {
    final gateway = InMemoryFirebaseStorageGateway();
    final storage = FirebaseFileStorage(gateway: gateway);
    await storage.upload(const FileUpload(path: 'a.txt', bytes: [9, 8]));
    final progress = <double>[];

    final bytes = await storage.download('a.txt', onProgress: progress.add);

    expect(bytes, [9, 8]);
    expect(progress.last, 1);
  });

  test('url builds a download link that contains the path', () async {
    final gateway = InMemoryFirebaseStorageGateway();
    final storage = FirebaseFileStorage(gateway: gateway);
    await storage.upload(const FileUpload(path: 'docs/report.pdf', bytes: [1]));

    final uri = await storage.url('docs/report.pdf');

    expect(uri.scheme, 'https');
    expect(uri.toString(), contains('report.pdf'));
  });

  test('a missing file is a fileNotFound Failure', () async {
    final storage = FirebaseFileStorage(
      gateway: InMemoryFirebaseStorageGateway(),
    );

    await expectLater(
      storage.download('missing.png'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.fileNotFound,
        ),
      ),
    );
    await expectLater(storage.url('missing.png'), throwsA(isA<Failure>()));
    await expectLater(
      storage.delete('missing.png'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.fileNotFound,
        ),
      ),
    );
  });

  test('empty paths are rejected before the gateway is called', () async {
    final gateway = InMemoryFirebaseStorageGateway();
    final storage = FirebaseFileStorage(gateway: gateway);

    await expectLater(
      storage.upload(const FileUpload(path: ' ', bytes: [1])),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
    expect(gateway.files, isEmpty);
  });

  test('unknown upload failures use the upload failure code', () async {
    final gateway = InMemoryFirebaseStorageGateway()
      ..error = StateError('boom');
    final storage = FirebaseFileStorage(gateway: gateway);

    await expectLater(
      storage.upload(const FileUpload(path: 'a.txt', bytes: [1])),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.fileUploadFailed,
        ),
      ),
    );
  });

  test('storage errors are mapped to Kiln failures', () async {
    final gateway = InMemoryFirebaseStorageGateway()
      ..error = FirebaseException(
        plugin: 'firebase_storage',
        code: 'unauthorized',
      );
    final storage = FirebaseFileStorage(gateway: gateway);

    await expectLater(
      storage.download('a.txt'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.authUnauthorized,
        ),
      ),
    );
  });

  test('delete removes the file and records the path', () async {
    final gateway = InMemoryFirebaseStorageGateway();
    final storage = FirebaseFileStorage(gateway: gateway);
    await storage.upload(const FileUpload(path: 'a.txt', bytes: [1]));

    await storage.delete('a.txt');

    expect(gateway.deleted, ['a.txt']);
    expect(gateway.files, isEmpty);
  });
}
