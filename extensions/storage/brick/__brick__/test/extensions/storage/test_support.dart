import 'package:{{app_name}}/extensions/storage/shared_preferences_storage.dart';
import 'package:{{app_name}}/extensions/storage/storage_config.dart';
import 'package:{{app_name}}/extensions/storage/storage_gateway.dart';

final class FakeStorageGateway implements StorageGateway {
  FakeStorageGateway({Map<String, String>? values})
    : values = <String, String>{...?values};

  final Map<String, String> values;
  bool failReads = false;
  bool failWrites = false;
  Object? keysError;

  @override
  Future<void> clear() async {
    values.clear();
  }

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<Set<String>> keys() async {
    final error = keysError;
    if (error != null) {
      throw error;
    }
    return values.keys.toSet();
  }

  @override
  Future<String?> read(String key) async {
    if (failReads) {
      throw StateError('read failed');
    }
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) {
      throw StateError('write failed');
    }
    values[key] = value;
  }
}

SharedPreferencesStorage createTestStorage({
  FakeStorageGateway? gateway,
  String prefix = 'app.',
}) {
  return SharedPreferencesStorage(
    gateway: gateway ?? FakeStorageGateway(),
    config: StorageConfig(prefix: prefix),
  );
}
