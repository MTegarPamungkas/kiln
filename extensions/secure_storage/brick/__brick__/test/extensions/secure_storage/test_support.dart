import 'package:{{app_name}}/extensions/secure_storage/keystore_secure_storage.dart';
import 'package:{{app_name}}/extensions/secure_storage/secure_storage_config.dart';
import 'package:{{app_name}}/extensions/secure_storage/secure_storage_gateway.dart';

final class FakeSecureStorageGateway implements SecureStorageGateway {
  FakeSecureStorageGateway({Map<String, String>? values})
    : values = <String, String>{...?values};

  final Map<String, String> values;
  bool failReads = false;
  Object? readAllError;

  @override
  Future<void> clear() async {
    values.clear();
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    if (failReads) {
      throw StateError('read failed');
    }
    return values[key];
  }

  @override
  Future<Map<String, String>> readAll() async {
    final error = readAllError;
    if (error != null) {
      throw error;
    }
    return Map<String, String>.unmodifiable(values);
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

KeystoreSecureStorage createTestSecureStorage({
  FakeSecureStorageGateway? gateway,
  String prefix = 'app.',
}) {
  return KeystoreSecureStorage(
    gateway: gateway ?? FakeSecureStorageGateway(),
    config: SecureStorageConfig(prefix: prefix),
  );
}
