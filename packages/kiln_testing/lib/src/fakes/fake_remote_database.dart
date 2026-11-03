import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// [RemoteDatabase] backed by nested maps, with programmable failures.
final class FakeRemoteDatabase implements RemoteDatabase {
  final Map<String, Map<String, Map<String, Object?>>> _data =
      <String, Map<String, Map<String, Object?>>>{};
  final StreamController<String> _changes = StreamController<String>.broadcast(
    sync: true,
  );

  int _counter = 0;
  Failure? failure;
  bool closed = false;

  Map<String, Map<String, Object?>> _collection(String collection) =>
      _data.putIfAbsent(collection, () => <String, Map<String, Object?>>{});

  Future<void> _maybeFail() async {
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
  }

  @override
  Future<Map<String, Object?>> create(
    String collection,
    Map<String, Object?> data,
  ) async {
    await _maybeFail();
    final id = 'doc_${++_counter}';
    final document = <String, Object?>{...data, 'id': id};
    _collection(collection)[id] = document;
    _changes.add(collection);
    return Map<String, Object?>.of(document);
  }

  @override
  Future<Map<String, Object?>?> read(String collection, String id) async {
    await _maybeFail();
    final document = _data[collection]?[id];
    return document == null ? null : Map<String, Object?>.of(document);
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String collection, {
    RemoteQuery? query,
  }) async {
    await _maybeFail();
    var documents = <Map<String, Object?>>[
      for (final document in _collection(collection).values)
        Map<String, Object?>.of(document),
    ];

    final filters = query?.filters ?? const <RemoteFilter>[];
    if (filters.isNotEmpty) {
      documents = documents
          .where((document) => filters.every((f) => _matches(document, f)))
          .toList();
    }

    final order = query?.orderBy ?? const <RemoteOrder>[];
    if (order.isNotEmpty) {
      documents.sort((left, right) {
        for (final clause in order) {
          final comparison = _compare(left[clause.field], right[clause.field]);
          if (comparison != 0) {
            return clause.direction == RemoteSortDirection.descending
                ? -comparison
                : comparison;
          }
        }
        return 0;
      });
    }

    final offset = query?.offset ?? 0;
    final sliced = documents.skip(offset);
    final limit = query?.limit;
    return (limit == null ? sliced : sliced.take(limit)).toList();
  }

  bool _matches(Map<String, Object?> document, RemoteFilter filter) {
    final actual = document[filter.field];
    return switch (filter.operator) {
      RemoteFilterOperator.equals => actual == filter.value,
      RemoteFilterOperator.notEquals => actual != filter.value,
      RemoteFilterOperator.greaterThan => _compare(actual, filter.value) > 0,
      RemoteFilterOperator.greaterThanOrEqual =>
        _compare(actual, filter.value) >= 0,
      RemoteFilterOperator.lessThan => _compare(actual, filter.value) < 0,
      RemoteFilterOperator.lessThanOrEqual =>
        _compare(actual, filter.value) <= 0,
      RemoteFilterOperator.inList =>
        filter.value is Iterable<Object?> &&
            (filter.value! as Iterable<Object?>).contains(actual),
      RemoteFilterOperator.notInList =>
        filter.value is! Iterable<Object?> ||
            !(filter.value! as Iterable<Object?>).contains(actual),
      RemoteFilterOperator.arrayContains =>
        actual is Iterable<Object?> && actual.contains(filter.value),
      RemoteFilterOperator.isNull => actual == null,
      RemoteFilterOperator.isNotNull => actual != null,
    };
  }

  int _compare(Object? left, Object? right) {
    if (left is Comparable<Object?> && right != null) {
      return left.compareTo(right);
    }
    return '$left'.compareTo('$right');
  }

  @override
  Future<Map<String, Object?>> update(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async {
    await _maybeFail();
    final existing = _data[collection]?[id];
    if (existing == null) {
      throw const Failure(
        code: FailureCode.remoteDatabaseNotFound,
        message: 'Document not found',
        kind: FailureKind.database,
      );
    }
    final updated = <String, Object?>{...existing, ...data, 'id': id};
    _collection(collection)[id] = updated;
    _changes.add(collection);
    return Map<String, Object?>.of(updated);
  }

  @override
  Future<void> delete(String collection, String id) async {
    await _maybeFail();
    if (_data[collection]?.remove(id) == null) {
      throw const Failure(
        code: FailureCode.remoteDatabaseNotFound,
        message: 'Document not found',
        kind: FailureKind.database,
      );
    }
    _changes.add(collection);
  }

  @override
  Stream<Map<String, Object?>?> watch(String collection, String id) async* {
    await _maybeFail();
    yield await read(collection, id);
    yield* _changes.stream
        .where((changed) => changed == collection)
        .asyncMap((_) => read(collection, id));
  }
}
