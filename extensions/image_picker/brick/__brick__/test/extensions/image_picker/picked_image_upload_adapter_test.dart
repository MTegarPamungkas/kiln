import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/image_picker/picked_image_upload_adapter.dart';
import 'package:{{app_name}}/extensions/image_picker/image_validator.dart';
import 'package:{{app_name}}/extensions/image_picker/media_picker_config.dart';

import 'test_support.dart';

void main() {
  test(
    'validates actual bytes instead of trusting size metadata before upload',
    () async {
      final storage = FakeFileStorage();
      final adapter = PickedImageUploadAdapter(
        storage: storage,
        validator: const ImageValidator(config: MediaPickerConfig(maxBytes: 2)),
      );
      expect(
        () => adapter.upload(
          const PickedImage(
            path: '/tmp/a.jpg',
            name: 'a.jpg',
            bytes: jpegSignature,
            sizeBytes: 1,
          ),
        ),
        throwsA(isA<Failure>()),
      );
      expect(storage.files, isEmpty);
    },
  );

  test('rejects names that can escape the upload directory', () {
    final storage = FakeFileStorage();
    final adapter = PickedImageUploadAdapter(storage: storage);
    expect(
      () => adapter.upload(
        const PickedImage(
          path: '/tmp/a.jpg',
          name: '../a.jpg',
          bytes: jpegSignature,
        ),
      ),
      throwsA(isA<Failure>()),
    );
    expect(storage.files, isEmpty);
  });
  test('uploads the image bytes with its content type', () async {
    final storage = FakeFileStorage();
    final adapter = PickedImageUploadAdapter(storage: storage);
    var progress = 0.0;
    const image = PickedImage(
      path: '/tmp/photo.jpg',
      name: 'photo.jpg',
      bytes: jpegSignature,
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
    expect(storage.files['images/photo.jpg'], jpegSignature);
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
      bytes: pngSignature,
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
