/// Detects image types from the first bytes instead of the plugin mime type.
final class MimeSniffer {
  const MimeSniffer._();

  static String? detect(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    if (bytes.length >= 6 &&
        _ascii(bytes, 0, 4) == 'GIF8' &&
        (bytes[4] == 0x37 || bytes[4] == 0x39) &&
        bytes[5] == 0x61) {
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        _ascii(bytes, 0, 4) == 'RIFF' &&
        _ascii(bytes, 8, 4) == 'WEBP') {
      return 'image/webp';
    }
    if (bytes.length >= 12 && _ascii(bytes, 4, 4) == 'ftyp') {
      final brand = _ascii(bytes, 8, 4);
      if (brand == 'avif' || brand == 'avis') {
        return 'image/avif';
      }
      if (brand == 'heic' ||
          brand == 'heix' ||
          brand == 'hevc' ||
          brand == 'mif1' ||
          brand == 'msf1') {
        return 'image/heic';
      }
    }
    return null;
  }

  static String _ascii(List<int> bytes, int offset, int length) {
    return String.fromCharCodes(bytes.skip(offset).take(length));
  }
}
