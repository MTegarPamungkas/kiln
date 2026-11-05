import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/image_picker/image_validator.dart';
import 'package:{{app_name}}/extensions/image_picker/media_picker_config.dart';

import 'test_support.dart';

void main() {
  test('accepts an allowed image within the size limit', () {
    const validator = ImageValidator(
      config: MediaPickerConfig(
        allowedTypes: <String>{'image/jpeg'},
        maxBytes: 10,
      ),
    );
    const image = PickedImage(
      path: '/tmp/photo.jpg',
      name: 'photo.jpg',
      bytes: <int>[0xFF, 0xD8, 0xFF],
      sizeBytes: 3,
    );

    expect(validator.ensureValid(image), 'image/jpeg');
  });

  test('rejects a type outside the allowlist', () {
    const validator = ImageValidator(
      config: MediaPickerConfig(allowedTypes: <String>{'image/jpeg'}),
    );
    final image = PickedImage(
      path: '/tmp/photo.png',
      name: 'photo.png',
      bytes: pngSignature,
      sizeBytes: pngSignature.length,
    );

    expect(
      () => validator.ensureValid(image),
      throwsA(
        isA<Failure>()
            .having((failure) => failure.code, 'code', FailureCode.mediaInvalid)
            .having((failure) => failure.kind, 'kind', FailureKind.validation),
      ),
    );
  });

  test('rejects an image above the size limit', () {
    const validator = ImageValidator(
      config: MediaPickerConfig(maxBytes: 10, allowedTypes: <String>{'image/jpeg'}),
    );
    final image = PickedImage(
      path: '/tmp/photo.jpg',
      name: 'photo.jpg',
      bytes: jpegSignature,
      sizeBytes: 11,
    );

    expect(
      () => validator.ensureValid(image),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.mediaInvalid,
        ),
      ),
    );
  });

  test('rejects an unrecognised image', () {
    const validator = ImageValidator();
    const image = PickedImage(
      path: '/tmp/file.bin',
      name: 'file.bin',
      bytes: <int>[1, 2, 3],
    );

    expect(() => validator.ensureValid(image), throwsA(isA<Failure>()));
  });

  test('falls back to the plugin mime type without bytes', () {
    const validator = ImageValidator();
    const image = PickedImage(
      path: '/tmp/photo.jpg',
      name: 'photo.jpg',
      mimeType: 'image/jpeg',
    );

    expect(validator.ensureValid(image), 'image/jpeg');
  });
}
