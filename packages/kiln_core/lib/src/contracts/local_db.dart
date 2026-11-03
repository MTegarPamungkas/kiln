/// One document stored in a local collection.
final class LocalRecord {
  const LocalRecord({required this.key, required this.data});

  final String key;
  final Map<String, Object?> data;
}

/// Query options supported by every local database implementation.
final class LocalQuery {
  const LocalQuery({
    this.where,
    this.orderBy,
    this.descending = false,
    this.limit,
    this.offset = 0,
  });

  final Map<String, Object?>? where;
  final String? orderBy;
  final bool descending;
  final int? limit;
  final int offset;
}

/// Stores documents on the device.
abstract interface class LocalDatabase {
  Future<void> put(String collection, String key, Map<String, Object?> data);

  Future<Map<String, Object?>?> get(String collection, String key);

  Future<List<LocalRecord>> query(String collection, {LocalQuery? query});

  Future<void> delete(String collection, String key);

  Stream<List<LocalRecord>> watch(String collection, {LocalQuery? query});

  Future<void> close();
}
