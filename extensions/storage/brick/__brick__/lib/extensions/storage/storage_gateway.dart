import 'package:shared_preferences/shared_preferences.dart';

/// Platform access that can be replaced by a fake in tests.
abstract interface class StorageGateway {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  Future<bool> containsKey(String key);

  Future<Set<String>> keys();

  Future<void> clear();
}

/// Gateway backed by SharedPreferencesAsync.
final class SharedPreferencesGateway implements StorageGateway {
  SharedPreferencesGateway({this.preferences});

  SharedPreferencesAsync? preferences;

  SharedPreferencesAsync get _instance =>
      preferences ??= SharedPreferencesAsync();

  @override
  Future<String?> read(String key) => _instance.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _instance.setString(key, value);

  @override
  Future<void> delete(String key) => _instance.remove(key);

  @override
  Future<bool> containsKey(String key) => _instance.containsKey(key);

  @override
  Future<Set<String>> keys() => _instance.getKeys();

  @override
  Future<void> clear() => _instance.clear();
}
