import 'package:kiln_core/kiln_core.dart';

/// A collection that converts between documents and a typed model.
final class TypedCollection<T> {
  const TypedCollection({
    required this.database,
    required this.collection,
    required this.fromJson,
    required this.toJson,
  });

  final LocalDatabase database;
  final String collection;
  final T Function(Map<String, Object?> data) fromJson;
  final Map<String, Object?> Function(T value) toJson;

  Future<void> put(String key, T value) {
    return database.put(collection, key, toJson(value));
  }

  Future<T?> get(String key) async {
    final data = await database.get(collection, key);
    return data == null ? null : fromJson(data);
  }

  Future<List<T>> query({LocalQuery? query}) async {
    final records = await database.query(collection, query: query);
    return <T>[for (final record in records) fromJson(record.data)];
  }

  Stream<List<T>> watch({LocalQuery? query}) {
    return database
        .watch(collection, query: query)
        .map(
          (records) => <T>[
            for (final record in records) fromJson(record.data),
          ],
        );
  }

  Future<void> delete(String key) => database.delete(collection, key);
}
