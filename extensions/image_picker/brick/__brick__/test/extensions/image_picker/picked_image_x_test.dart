import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/image_picker/picked_image_x.dart';

void main() {
  test('formats sizes with Indonesian separators', () {
    const bytes = PickedImage(path: '/a', name: 'a', sizeBytes: 900);
    const kilobytes = PickedImage(path: '/a', name: 'a', sizeBytes: 1536);
    const megabytes = PickedImage(path: '/a', name: 'a', sizeBytes: 1200000);
    const unknown = PickedImage(path: '/a', name: 'a');

    expect(bytes.readableSize, '900 B');
    expect(kilobytes.readableSize, '1,5 KB');
    expect(megabytes.readableSize, '1,1 MB');
    expect(unknown.readableSize, isNull);
  });

  test('builds an image provider from the bytes', () {
    const image = PickedImage(
      path: '/tmp/a.jpg',
      name: 'a.jpg',
      bytes: <int>[1, 2, 3],
    );

    expect(image.toImageProvider(), isA<MemoryImage>());
  });

  test('requires bytes to build an image provider', () {
    const image = PickedImage(path: '/tmp/a.jpg', name: 'a.jpg');

    expect(
      image.toImageProvider,
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.mediaInvalid,
        ),
      ),
    );
  });
}
