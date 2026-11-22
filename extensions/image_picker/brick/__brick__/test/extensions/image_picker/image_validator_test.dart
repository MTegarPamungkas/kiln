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
      config: MediaPickerConfig(
        maxBytes: 10,
        allowedTypes: <String>{'image/jpeg'},
      ),
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

  test('accepts a small image and reports its type', () {
    const validator = ImageValidator(
      config: MediaPickerConfig(allowedTypes: <String>{'image/png'}),
    );
    final image = PickedImage(
      path: '/tmp/small.png',
      name: 'small.png',
      bytes: tinyPng,
      sizeBytes: tinyPng.length,
    );

    expect(validator.ensureValid(image), 'image/png');
  });

  test('rejects a header above the decoded width and height limits', () {
    const validator = ImageValidator(
      config: MediaPickerConfig(
        allowedTypes: <String>{'image/png'},
        maxDecodedWidth: 1000,
        maxDecodedHeight: 1000,
        maxDecodedPixels: 1000000,
      ),
    );
    final bytes = pngWithSize(2000, 2000);
    final image = PickedImage(
      path: '/tmp/big.png',
      name: 'big.png',
      bytes: bytes,
      sizeBytes: bytes.length,
    );

    expect(
      () => validator.ensureValid(image),
      throwsA(
        isA<Failure>()
            .having((failure) => failure.code, 'code', FailureCode.mediaInvalid)
            .having((failure) => failure.kind, 'kind', FailureKind.validation)
            .having((failure) => failure.details['width'], 'width', 2000)
            .having(
              (failure) => failure.details['max_pixels'],
              'max_pixels',
              1000000,
            ),
      ),
    );
  });

  test('rejects a pixel count over the limit within the width limits', () {
    const validator = ImageValidator(
      config: MediaPickerConfig(
        allowedTypes: <String>{'image/png'},
        maxDecodedPixels: 4000000,
      ),
    );
    final bytes = pngWithSize(4000, 4000);
    final image = PickedImage(
      path: '/tmp/large.png',
      name: 'large.png',
      bytes: bytes,
      sizeBytes: bytes.length,
    );

    expect(
      () => validator.ensureValid(image),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.details['pixels'],
          'pixels',
          16000000,
        ),
      ),
    );
  });

  test('keeps accepting a header it cannot measure', () {
    const validator = ImageValidator(
      config: MediaPickerConfig(
        allowedTypes: <String>{'image/jpeg'},
        maxDecodedPixels: 1,
      ),
    );
    const image = PickedImage(
      path: '/tmp/photo.jpg',
      name: 'photo.jpg',
      bytes: jpegSignature,
      sizeBytes: 3,
    );

    expect(validator.ensureValid(image), 'image/jpeg');
  });
}
