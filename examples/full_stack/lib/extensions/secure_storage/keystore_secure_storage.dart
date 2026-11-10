import 'package:kiln_core/kiln_core.dart';

import 'secure_storage_config.dart';
import 'secure_storage_failure_mapper.dart';
import 'secure_storage_gateway.dart';

/// [SecureStorage] backed by Keychain/Keystore through a gateway.
final class KeystoreSecureStorage implements SecureStorage {
  KeystoreSecureStorage({
    required this.gateway,
    this.config = SecureStorageConfig.defaults,
  });

  final SecureStorageGateway gateway;
  final SecureStorageConfig config;

  String _key(String key) => '${config.prefix}$key';

  @override
  Future<String?> read(String key) async {
    try {
      return await gateway.read(_key(key));
    } catch (error, stackTrace) {
      throw mapSecureStorageError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await gateway.write(_key(key), value);
    } catch (error, stackTrace) {
      throw mapSecureStorageError(
        error,
        stackTrace: stackTrace,
        code: FailureCode.secureStorageWriteFailed,
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await gateway.delete(_key(key));
    } catch (error, stackTrace) {
      throw mapSecureStorageError(
        error,
        stackTrace: stackTrace,
        code: FailureCode.secureStorageWriteFailed,
      );
    }
  }

  @override
  Future<Map<String, String>> readAll() async {
    try {
      final all = await gateway.readAll();
      return <String, String>{
        for (final entry in all.entries)
          if (entry.key.startsWith(config.prefix))
            entry.key.substring(config.prefix.length): entry.value,
      };
    } catch (error, stackTrace) {
      throw mapSecureStorageError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> clear() async {
    try {
      final all = await gateway.readAll();
      for (final key in all.keys) {
        if (key.startsWith(config.prefix)) {
          await gateway.delete(key);
        }
      }
    } catch (error, stackTrace) {
      throw mapSecureStorageError(
        error,
        stackTrace: stackTrace,
        code: FailureCode.secureStorageWriteFailed,
      );
    }
  }
}
