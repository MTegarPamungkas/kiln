import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/image_picker/image_dimensions.dart';

import 'test_support.dart';

void main() {
  test('reads PNG dimensions from the IHDR chunk', () {
    expect(ImageDimensionsReader.read(tinyPng), const ImageDimensions(1, 1));
    expect(
      ImageDimensionsReader.read(pngWithSize(4096, 2048)),
      const ImageDimensions(4096, 2048),
    );
  });

  test('reads JPEG dimensions from the start-of-frame segment', () {
    expect(
      ImageDimensionsReader.read(jpegWithSize(3000, 2000)),
      const ImageDimensions(3000, 2000),
    );
  });

  test('skips JPEG segments before the frame header', () {
    final bytes = <int>[
      0xFF, 0xD8,
      // APP0 with a 16-byte segment, including its own length field.
      0xFF, 0xE0, 0x00, 0x10,
      ...List<int>.filled(14, 0x00),
      // A restart marker carries no length field.
      0xFF, 0xD0,
      ...jpegWithSize(640, 480).skip(2),
    ];

    expect(ImageDimensionsReader.read(bytes), const ImageDimensions(640, 480));
  });

  test('reads GIF dimensions from the logical screen descriptor', () {
    expect(
      ImageDimensionsReader.read(gifWithSize(320, 240)),
      const ImageDimensions(320, 240),
    );
  });

  test('reads WebP canvas dimensions from VP8X', () {
    expect(
      ImageDimensionsReader.read(webpVp8x(8000, 6000)),
      const ImageDimensions(8000, 6000),
    );
  });

  test('reads AVIF dimensions from the ispe box', () {
    expect(
      ImageDimensionsReader.read(avifWithSize(12000, 9000)),
      const ImageDimensions(12000, 9000),
    );
  });

  test('reports the pixel count', () {
    expect(const ImageDimensions(3, 4).pixels, 12);
  });

  test('returns null for truncated or unknown headers', () {
    expect(ImageDimensionsReader.read(const <int>[0x89, 0x50, 0x4E]), isNull);
    expect(ImageDimensionsReader.read(<int>[1, 2, 3, 4, 5]), isNull);

    // ISO-BMFF container without an ispe box.
    final noIspe = List<int>.of(avifWithSize(10, 10));
    noIspe[20] = 0x78;
    noIspe[21] = 0x78;
    noIspe[22] = 0x78;
    noIspe[23] = 0x78;
    expect(ImageDimensionsReader.read(noIspe), isNull);

    // A WebP chunk with no frame header we understand.
    final unknownChunk = <int>[
      ...'RIFF'.codeUnits,
      0x00,
      0x00,
      0x00,
      0x00,
      ...'WEBP'.codeUnits,
      ...'VP8?'.codeUnits,
      0x0A,
      0x00,
      0x00,
      0x00,
      ...List<int>.filled(10, 0x00),
    ];
    expect(ImageDimensionsReader.read(unknownChunk), isNull);
  });
}
