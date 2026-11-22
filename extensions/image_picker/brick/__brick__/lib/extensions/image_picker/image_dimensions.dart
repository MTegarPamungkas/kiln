/// Intrinsic pixel size of an encoded image.
final class ImageDimensions {
  const ImageDimensions(this.width, this.height);

  final int width;
  final int height;

  int get pixels => width * height;

  @override
  bool operator ==(Object other) =>
      other is ImageDimensions &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => '${width}x$height';
}

/// Reads the pixel size from the encoded header, without decoding the image.
///
/// Supports the formats the extension allows: PNG, JPEG, GIF, WebP, and the
/// ISO-BMFF `ispe` box used by HEIC/AVIF. Returns null when the header is
/// truncated, malformed, or belongs to another format; a payload without a
/// readable header cannot be decoded into a full bitmap either, so the caller
/// only enforces dimension limits on what it can measure.
final class ImageDimensionsReader {
  const ImageDimensionsReader._();

  static ImageDimensions? read(List<int> bytes) {
    return _png(bytes) ??
        _jpeg(bytes) ??
        _gif(bytes) ??
        _webp(bytes) ??
        _isoBmff(bytes);
  }

  static ImageDimensions? _png(List<int> bytes) {
    if (bytes.length < 24) {
      return null;
    }
    const signature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) {
        return null;
      }
    }
    if (_ascii(bytes, 12, 4) != 'IHDR') {
      return null;
    }
    return ImageDimensions(_be32(bytes, 16), _be32(bytes, 20));
  }

  static ImageDimensions? _jpeg(List<int> bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return null;
    }
    var index = 2;
    while (index + 3 < bytes.length) {
      if (bytes[index] != 0xFF) {
        index++;
        continue;
      }
      var marker = bytes[index + 1];
      // Fill bytes are allowed between segments.
      while (marker == 0xFF && index + 2 < bytes.length) {
        index++;
        marker = bytes[index + 1];
      }
      if (marker == 0xD8 ||
          marker == 0xD9 ||
          (marker >= 0xD0 && marker <= 0xD7)) {
        index += 2;
        continue;
      }
      if (index + 3 >= bytes.length) {
        return null;
      }
      final length = _be16(bytes, index + 2);
      if (length < 2) {
        return null;
      }
      final isStartOfFrame =
          marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (isStartOfFrame) {
        if (index + 9 >= bytes.length) {
          return null;
        }
        return ImageDimensions(
          _be16(bytes, index + 7),
          _be16(bytes, index + 5),
        );
      }
      index += 2 + length;
    }
    return null;
  }

  static ImageDimensions? _gif(List<int> bytes) {
    if (bytes.length < 10 || _ascii(bytes, 0, 4) != 'GIF8') {
      return null;
    }
    return ImageDimensions(_le16(bytes, 6), _le16(bytes, 8));
  }

  static ImageDimensions? _webp(List<int> bytes) {
    if (bytes.length < 30 ||
        _ascii(bytes, 0, 4) != 'RIFF' ||
        _ascii(bytes, 8, 4) != 'WEBP') {
      return null;
    }
    final chunk = _ascii(bytes, 12, 4);
    if (chunk == 'VP8X') {
      return ImageDimensions(_le24(bytes, 24) + 1, _le24(bytes, 27) + 1);
    }
    if (chunk == 'VP8 ') {
      if (bytes.length < 30 ||
          bytes[23] != 0x9D ||
          bytes[24] != 0x01 ||
          bytes[25] != 0x2A) {
        return null;
      }
      return ImageDimensions(
        _le16(bytes, 26) & 0x3FFF,
        _le16(bytes, 28) & 0x3FFF,
      );
    }
    if (chunk == 'VP8L') {
      if (bytes.length < 25 || bytes[20] != 0x2F) {
        return null;
      }
      final bits =
          bytes[21] | (bytes[22] << 8) | (bytes[23] << 16) | (bytes[24] << 24);
      return ImageDimensions((bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1);
    }
    return null;
  }

  /// HEIC/AVIF store the display size in an `ispe` box.
  static ImageDimensions? _isoBmff(List<int> bytes) {
    if (bytes.length < 16 || _ascii(bytes, 4, 4) != 'ftyp') {
      return null;
    }
    for (var index = 0; index + 12 <= bytes.length; index++) {
      if (bytes[index] != 0x69 ||
          bytes[index + 1] != 0x73 ||
          bytes[index + 2] != 0x70 ||
          bytes[index + 3] != 0x65) {
        continue;
      }
      // 'ispe' is followed by version/flags (4 bytes) then width and height.
      final widthAt = index + 8;
      if (widthAt + 8 > bytes.length) {
        return null;
      }
      return ImageDimensions(_be32(bytes, widthAt), _be32(bytes, widthAt + 4));
    }
    return null;
  }

  static String _ascii(List<int> bytes, int offset, int length) {
    if (offset + length > bytes.length) {
      return '';
    }
    return String.fromCharCodes(bytes.skip(offset).take(length));
  }

  static int _be16(List<int> bytes, int offset) =>
      (bytes[offset] << 8) | bytes[offset + 1];

  static int _be32(List<int> bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];

  static int _le16(List<int> bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8);

  static int _le24(List<int> bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);
}
