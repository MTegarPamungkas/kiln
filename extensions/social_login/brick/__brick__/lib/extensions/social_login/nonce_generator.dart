import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;

/// Creates cryptographically secure nonces for Apple.
final class NonceGenerator {
  NonceGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  String generate({int byteLength = 32}) {
    final bytes = List<int>.generate(byteLength, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String sha256(String value) {
    return crypto.sha256.convert(utf8.encode(value)).toString();
  }
}
