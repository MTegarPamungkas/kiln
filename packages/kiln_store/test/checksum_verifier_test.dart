import 'dart:convert';

import 'package:kiln_store/kiln_store.dart';
import 'package:test/test.dart';

void main() {
  const verifier = ChecksumVerifier();
  final bytes = utf8.encode('hello');
  const helloDigest =
      '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';

  group('ChecksumVerifier', () {
    test('computes a lower case SHA-256 digest', () {
      expect(sha256Hex(bytes), helloDigest);
      expect(sha256Hex(const <int>[]), hasLength(64));
    });

    test('accepts matching lower case and upper case digests', () {
      expect(() => verifier.verify(bytes, helloDigest), returnsNormally);
      expect(
        () => verifier.verify(bytes, helloDigest.toUpperCase()),
        returnsNormally,
      );
      expect(() => verifier.verify(bytes, '  $helloDigest  '), returnsNormally);
    });

    test('throws store.checksum_mismatch for a different digest', () {
      expect(
        () => verifier.verify(bytes, 'a' * 64),
        throwsA(
          isA<KilnStoreException>()
              .having((error) => error.code, 'code', 'store.checksum_mismatch')
              .having((error) => error.details['actual'], 'actual', helloDigest)
              .having(
                (error) => error.details['expected'],
                'expected',
                'a' * 64,
              ),
        ),
      );
    });

    test('throws store.checksum_mismatch for malformed digests', () {
      for (final expected in <String>['', 'abc', 'z' * 64, '0' * 63]) {
        expect(
          () => verifier.verify(bytes, expected),
          throwsA(
            isA<KilnStoreException>().having(
              (error) => error.code,
              'code',
              'store.checksum_mismatch',
            ),
          ),
          reason: 'expected "$expected" to be rejected',
        );
      }
    });

    test('includes an actionable suggestion', () {
      final error = _capture(() => verifier.verify(bytes, 'b' * 64));

      expect(error.suggestion, isNotNull);
      expect(error.toString(), contains('store.checksum_mismatch'));
      expect(error.toString(), contains('Hint:'));
    });
  });
}

KilnStoreException _capture(void Function() action) {
  try {
    action();
  } on KilnStoreException catch (error) {
    return error;
  }
  fail('expected a KilnStoreException');
}
