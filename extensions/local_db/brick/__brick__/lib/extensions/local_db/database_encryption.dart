import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:kiln_core/kiln_core.dart';
import 'package:sembast/sembast.dart';

/// Optional AES-GCM codec whose key lives in SecureStorage.
final class DatabaseEncryption {
  const DatabaseEncryption();

  Future<SembastCodec?> codec({
    required SecureStorage? secureStorage,
    required String databaseName,
  }) async {
    if (secureStorage == null) {
      return null;
    }
    final keyName = 'local_db.$databaseName.key';
    var keyBase64 = await secureStorage.read(keyName);
    if (keyBase64 == null) {
      keyBase64 = encrypt.Key.fromSecureRandom(32).base64;
      await secureStorage.write(keyName, keyBase64);
    }
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key.fromBase64(keyBase64), mode: encrypt.AESMode.gcm),
    );
    return SembastCodec(
      signature: 'aes-gcm',
      codec: _AesGcmCodec(encrypter),
    );
  }
}

final class _AesGcmCodec extends Codec<Object?, String> {
  const _AesGcmCodec(this.encrypter);

  final encrypt.Encrypter encrypter;

  @override
  Converter<Object?, String> get encoder => _AesEncoder(encrypter);

  @override
  Converter<String, Object?> get decoder => _AesDecoder(encrypter);
}

final class _AesEncoder extends Converter<Object?, String> {
  const _AesEncoder(this.encrypter);

  final encrypt.Encrypter encrypter;

  @override
  String convert(Object? input) {
    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypted = encrypter.encrypt(jsonEncode(input), iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }
}

final class _AesDecoder extends Converter<String, Object?> {
  const _AesDecoder(this.encrypter);

  final encrypt.Encrypter encrypter;

  @override
  Object? convert(String input) {
    final separator = input.indexOf(':');
    if (separator < 0) {
      throw const FormatException('Invalid encrypted value');
    }
    final iv = encrypt.IV.fromBase64(input.substring(0, separator));
    final cipher = input.substring(separator + 1);
    return jsonDecode(encrypter.decrypt64(cipher, iv: iv));
  }
}
