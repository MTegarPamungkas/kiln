import 'package:kiln_core/kiln_core.dart';

/// [Storage] backed by a map in memory.
final class InMemoryStorage implements Storage {
  InMemoryStorage([Map<String, String>? values])
    : _values = <String, String>{...?values};

  final Map<String, String> _values;
  int readCount = 0;
  int writeCount = 0;

  Map<String, String> get snapshot => Map<String, String>.unmodifiable(_values);

  @override
  Future<String?> read(String key) async {
    readCount++;
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    writeCount++;
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<Set<String>> keys() async => _values.keys.toSet();

  @override
  Future<void> clear() async {
    _values.clear();
  }
}
