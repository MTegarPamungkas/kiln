import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// [LocalDatabase] backed by nested maps in memory.
final class FakeLocalDatabase implements LocalDatabase {
  final Map<String, Map<String, Map<String, Object?>>> _data =
      <String, Map<String, Map<String, Object?>>>{};
  final StreamController<String> _changes = StreamController<String>.broadcast(
    sync: true,
  );

  bool closed = false;

  Map<String, Map<String, Object?>> _collection(String collection) =>
      _data.putIfAbsent(collection, () => <String, Map<String, Object?>>{});

  @override
  Future<void> put(
    String collection,
    String key,
    Map<String, Object?> data,
  ) async {
    _collection(collection)[key] = Map<String, Object?>.of(data);
    _changes.add(collection);
  }

  @override
  Future<Map<String, Object?>?> get(String collection, String key) async {
    final data = _data[collection]?[key];
    return data == null ? null : Map<String, Object?>.of(data);
  }

  @override
  Future<List<LocalRecord>> query(
    String collection, {
    LocalQuery? query,
  }) async {
    var records = <LocalRecord>[
      for (final entry in _collection(collection).entries)
        LocalRecord(key: entry.key, data: Map<String, Object?>.of(entry.value)),
    ];

    final where = query?.where;
    if (where != null) {
      records = records.where((record) {
        return where.entries.every(
          (filter) => record.data[filter.key] == filter.value,
        );
      }).toList();
    }

    final orderBy = query?.orderBy;
    if (orderBy != null) {
      records.sort((left, right) {
        final comparison = _compare(left.data[orderBy], right.data[orderBy]);
        return query!.descending ? -comparison : comparison;
      });
    }

    final offset = query?.offset ?? 0;
    final sliced = records.skip(offset);
    final limit = query?.limit;
    return (limit == null ? sliced : sliced.take(limit)).toList();
  }

  int _compare(Object? left, Object? right) {
    if (left is Comparable<Object?> && right != null) {
      return left.compareTo(right);
    }
    return '$left'.compareTo('$right');
  }

  @override
  Future<void> delete(String collection, String key) async {
    if (_data[collection]?.remove(key) != null) {
      _changes.add(collection);
    }
  }

  @override
  Stream<List<LocalRecord>> watch(
    String collection, {
    LocalQuery? query,
  }) async* {
    yield await this.query(collection, query: query);
    yield* _changes.stream
        .where((changed) => changed == collection)
        .asyncMap((_) => this.query(collection, query: query));
  }

  @override
  Future<void> close() async {
    closed = true;
    await _changes.close();
  }
}
