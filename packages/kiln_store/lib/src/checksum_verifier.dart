import 'package:crypto/crypto.dart';

import 'kiln_store_exception.dart';

/// Verifies SHA-256 checksums of downloaded extension archives.
final class ChecksumVerifier {
  const ChecksumVerifier();

  static final RegExp _hexPattern = RegExp(r'^[a-fA-F0-9]{64}$');

  /// Throws [KilnStoreException] with code `store.checksum_mismatch` unless
  /// [bytes] hash to [expectedSha256].
  ///
  /// Both lower and upper case hexadecimal digests are accepted.
  void verify(List<int> bytes, String expectedSha256) {
    final expected = expectedSha256.trim().toLowerCase();
    final actual = sha256Hex(bytes);
    if (!_hexPattern.hasMatch(expected) || actual != expected) {
      throw KilnStoreException(
        'Archive checksum does not match the registry index.',
        code: 'store.checksum_mismatch',
        suggestion:
            'Download the archive again; the registry entry may be stale.',
        details: <String, Object?>{'expected': expected, 'actual': actual},
      );
    }
  }
}

/// Lower case SHA-256 digest of [bytes].
String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();
