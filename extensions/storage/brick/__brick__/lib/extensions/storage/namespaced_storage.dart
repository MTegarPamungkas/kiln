import 'package:kiln_core/kiln_core.dart';

/// Gives one owner a private prefix inside a shared [Storage].
final class NamespacedStorage implements Storage {
  NamespacedStorage({required this.inner, required this.namespace});

  final Storage inner;
  final String namespace;

  String _key(String key) => '$namespace.$key';

  @override
  Future<String?> read(String key) => inner.read(_key(key));

  @override
  Future<void> write(String key, String value) =>
      inner.write(_key(key), value);

  @override
  Future<void> delete(String key) => inner.delete(_key(key));

  @override
  Future<bool> containsKey(String key) => inner.containsKey(_key(key));

  @override
  Future<Set<String>> keys() async {
    final prefix = '$namespace.';
    final all = await inner.keys();
    return <String>{
      for (final key in all)
        if (key.startsWith(prefix)) key.substring(prefix.length),
    };
  }

  @override
  Future<void> clear() async {
    final prefix = '$namespace.';
    for (final key in await inner.keys()) {
      if (key.startsWith(prefix)) {
        await inner.delete(key);
      }
    }
  }
}
