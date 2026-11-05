import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/image_picker/picked_image_upload_adapter.dart';

void main() {
  test('uploads the image bytes with its content type', () async {
    final storage = FakeFileStorage();
    final adapter = PickedImageUploadAdapter(storage: storage);
    var progress = 0.0;
    const image = PickedImage(
      path: '/tmp/photo.jpg',
      name: 'photo.jpg',
      bytes: <int>[1, 2, 3],
      mimeType: 'image/jpeg',
      sizeBytes: 3,
    );

    final stored = await adapter.upload(
      image,
      onProgress: (value) => progress = value,
      metadata: const <String, String>{'purpose': 'avatar'},
    );

    expect(stored.path, 'images/photo.jpg');
    expect(stored.contentType, 'image/jpeg');
    expect(storage.files['images/photo.jpg'], <int>[1, 2, 3]);
    expect(progress, 1);
  });

  test('honours a custom directory', () async {
    final storage = FakeFileStorage();
    final adapter = PickedImageUploadAdapter(
      storage: storage,
      directory: 'avatars',
    );
    const image = PickedImage(
      path: '/tmp/a.png',
      name: 'a.png',
      bytes: <int>[1],
      mimeType: 'image/png',
    );

    await adapter.upload(image);

    expect(storage.files.keys, ['avatars/a.png']);
  });

  test('requires bytes before uploading', () async {
    final adapter = PickedImageUploadAdapter(storage: FakeFileStorage());
    const image = PickedImage(path: '/tmp/a.jpg', name: 'a.jpg');

    expect(
      () => adapter.upload(image),
      throwsA(
        isA<Failure>()
            .having((failure) => failure.code, 'code', FailureCode.mediaInvalid)
            .having((failure) => failure.kind, 'kind', FailureKind.validation),
      ),
    );
  });
}
