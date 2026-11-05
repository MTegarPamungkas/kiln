/// Simple key-value storage that survives application restarts.
abstract interface class Storage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  Future<bool> containsKey(String key);

  Future<Set<String>> keys();

  Future<void> clear();
}
