import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage_config.dart';

/// Platform secure storage access that can be faked in tests.
abstract interface class SecureStorageGateway {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  Future<Map<String, String>> readAll();

  Future<void> clear();
}

/// Gateway backed by FlutterSecureStorage.
final class FlutterSecureStorageGateway implements SecureStorageGateway {
  FlutterSecureStorageGateway({
    this.config = SecureStorageConfig.defaults,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final SecureStorageConfig config;
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) {
    return _storage.read(
      key: key,
      iOptions: config.ios,
      aOptions: config.android,
      webOptions: config.web,
    );
  }

  @override
  Future<void> write(String key, String value) {
    return _storage.write(
      key: key,
      value: value,
      iOptions: config.ios,
      aOptions: config.android,
      webOptions: config.web,
    );
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(
      key: key,
      iOptions: config.ios,
      aOptions: config.android,
      webOptions: config.web,
    );
  }

  @override
  Future<Map<String, String>> readAll() {
    return _storage.readAll(
      iOptions: config.ios,
      aOptions: config.android,
      webOptions: config.web,
    );
  }

  @override
  Future<void> clear() {
    return _storage.deleteAll(
      iOptions: config.ios,
      aOptions: config.android,
      webOptions: config.web,
    );
  }
}
