import 'package:kiln_core/kiln_core.dart';

/// [SecureStorage] backed by a map in memory, without a real keychain.
final class InMemorySecureStorage implements SecureStorage {
  InMemorySecureStorage([Map<String, String>? values])
    : _values = <String, String>{...?values};

  final Map<String, String> _values;

  Map<String, String> get snapshot => Map<String, String>.unmodifiable(_values);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<Map<String, String>> readAll() async =>
      Map<String, String>.unmodifiable(_values);

  @override
  Future<void> clear() async {
    _values.clear();
  }
}
