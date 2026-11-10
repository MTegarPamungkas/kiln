import 'package:kiln_core/kiln_core.dart';

/// Gives one extension a private prefix inside a shared SecureStorage.
final class NamespacedSecureStorage implements SecureStorage {
  NamespacedSecureStorage({required this.inner, required this.namespace});

  final SecureStorage inner;
  final String namespace;

  String _key(String key) => '$namespace.$key';

  @override
  Future<String?> read(String key) => inner.read(_key(key));

  @override
  Future<void> write(String key, String value) => inner.write(_key(key), value);

  @override
  Future<void> delete(String key) => inner.delete(_key(key));

  @override
  Future<Map<String, String>> readAll() async {
    final prefix = '$namespace.';
    final all = await inner.readAll();
    return <String, String>{
      for (final entry in all.entries)
        if (entry.key.startsWith(prefix))
          entry.key.substring(prefix.length): entry.value,
    };
  }

  @override
  Future<void> clear() async {
    final prefix = '$namespace.';
    for (final key in (await inner.readAll()).keys) {
      if (key.startsWith(prefix)) {
        await inner.delete(key);
      }
    }
  }
}
