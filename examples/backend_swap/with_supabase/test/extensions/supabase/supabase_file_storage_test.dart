import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:with_supabase/extensions/supabase/supabase_file_storage.dart';

import 'test_support.dart';

void main() {
  late FakeSupabaseStorageGateway gateway;
  late SupabaseFileStorage storage;

  setUp(() {
    gateway = FakeSupabaseStorageGateway();
    storage = SupabaseFileStorage(gateway: gateway);
  });

  test('upload returns path and file size', () async {
    final stored = await storage.upload(
      const FileUpload(
        path: 'avatars/user-1.png',
        bytes: <int>[1, 2, 3, 4],
        contentType: 'image/png',
      ),
    );

    expect(stored.path, 'avatars/user-1.png');
    expect(stored.size, 4);
    expect(stored.contentType, 'image/png');
    expect(gateway.uploadedPaths, ['avatars/user-1.png']);
    expect(gateway.files['avatars/user-1.png'], <int>[1, 2, 3, 4]);
  });

  test('upload melaporkan progres sampai selesai', () async {
    final progress = <double>[];

    await storage.upload(
      const FileUpload(path: 'a.txt', bytes: <int>[9]),
      onProgress: progress.add,
    );

    expect(progress, isNotEmpty);
    expect(progress.last, 1.0);
  });

  test('download returns the uploaded bytes', () async {
    await storage.upload(
      const FileUpload(path: 'a.txt', bytes: <int>[7, 8, 9]),
    );

    expect(await storage.download('a.txt'), <int>[7, 8, 9]);
  });

  test('downloading a missing file becomes file.not_found', () async {
    await expectLater(
      storage.download('missing.txt'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.fileNotFound,
        ),
      ),
    );
  });

  test('url uses a signed URL with the default lifetime', () async {
    final uri = await storage.url('avatars/user-1.png');

    expect(uri.scheme, 'https');
    expect(uri.toString(), contains('avatars/user-1.png'));
    expect(gateway.signedPaths, ['avatars/user-1.png']);
    expect(gateway.signedLifetimes.single, const Duration(hours: 1));
  });

  test('url accepts a custom lifetime', () async {
    await storage.url('a.txt', expiresIn: const Duration(minutes: 5));

    expect(gateway.signedLifetimes.single, const Duration(minutes: 5));
  });

  test('url rejects a zero lifetime', () async {
    await expectLater(
      storage.url('a.txt', expiresIn: Duration.zero),
      throwsA(
        isA<Failure>().having(
          (value) => value.kind,
          'kind',
          FailureKind.validation,
        ),
      ),
    );
    expect(gateway.signedPaths, isEmpty);
  });

  test('delete removes the file from the bucket', () async {
    await storage.upload(const FileUpload(path: 'a.txt', bytes: <int>[1]));

    await storage.delete('a.txt');

    expect(gateway.deletedPaths, ['a.txt']);
    expect(gateway.files, isEmpty);
  });

  test('deleting a missing file becomes file.not_found', () async {
    await expectLater(
      storage.delete('missing.txt'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.fileNotFound,
        ),
      ),
    );
  });

  test('an SDK error during upload becomes file.upload_failed', () async {
    gateway.failure = const StorageException(
      'Internal error',
      statusCode: '500',
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

  test('an invalid path is rejected before calling the SDK', () async {
    for (final path in <String>[
      '',
      '/absolute.txt',
      '../escape.txt',
      'a b?.txt',
    ]) {
      await expectLater(
        storage.download(path),
        throwsA(
          isA<Failure>().having(
            (value) => value.code,
            'code',
            FailureCode.validationInvalidInput,
          ),
        ),
      );
    }
  });
}
