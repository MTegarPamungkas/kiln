import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/image_picker/mime_sniffer.dart';

void main() {
  test('detects jpeg', () {
    expect(MimeSniffer.detect(<int>[0xFF, 0xD8, 0xFF, 0xE0]), 'image/jpeg');
  });

  test('detects png', () {
    expect(
      MimeSniffer.detect(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]),
      'image/png',
    );
  });

  test('detects gif', () {
    expect(
      MimeSniffer.detect('GIF89a'.codeUnits),
      'image/gif',
    );
    expect(
      MimeSniffer.detect('GIF87a'.codeUnits),
      'image/gif',
    );
  });

  test('detects webp', () {
    expect(
      MimeSniffer.detect(<int>[
        ...'RIFF'.codeUnits,
        0,
        0,
        0,
        0,
        ...'WEBP'.codeUnits,
      ]),
      'image/webp',
    );
  });

  test('detects heic and avif brands', () {
    List<int> box(String brand) => <int>[
      0,
      0,
      0,
      0x18,
      ...'ftyp'.codeUnits,
      ...brand.codeUnits,
      0,
      0,
      0,
      0,
    ];

    expect(MimeSniffer.detect(box('heic')), 'image/heic');
    expect(MimeSniffer.detect(box('mif1')), 'image/heic');
    expect(MimeSniffer.detect(box('avif')), 'image/avif');
  });

  test('returns null for unknown or truncated data', () {
    expect(MimeSniffer.detect(<int>[1, 2, 3]), isNull);
    expect(MimeSniffer.detect(const <int>[]), isNull);
    expect(MimeSniffer.detect(<int>[0x89, 0x50]), isNull);
  });
}
