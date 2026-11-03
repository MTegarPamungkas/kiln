/// Comparison used by a [RemoteFilter].
enum RemoteFilterOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  inList,
  notInList,
  arrayContains,
  isNull,
  isNotNull,
}

/// One condition in a [RemoteQuery].
final class RemoteFilter {
  const RemoteFilter(this.field, this.operator, [this.value]);

  final String field;
  final RemoteFilterOperator operator;
  final Object? value;
}

/// Sort direction for [RemoteOrder].
enum RemoteSortDirection { ascending, descending }

/// One sort clause in a [RemoteQuery].
final class RemoteOrder {
  const RemoteOrder(
    this.field, {
    this.direction = RemoteSortDirection.ascending,
  });

  final String field;
  final RemoteSortDirection direction;
}

/// Backend-neutral query over a remote collection.
final class RemoteQuery {
  const RemoteQuery({
    this.filters = const <RemoteFilter>[],
    this.orderBy = const <RemoteOrder>[],
    this.limit,
    this.offset = 0,
  });

  final List<RemoteFilter> filters;
  final List<RemoteOrder> orderBy;
  final int? limit;
  final int offset;
}

/// CRUD and realtime access to documents stored by a backend.
abstract interface class RemoteDatabase {
  Future<Map<String, Object?>> create(
    String collection,
    Map<String, Object?> data,
  );

  Future<Map<String, Object?>?> read(String collection, String id);

  Future<List<Map<String, Object?>>> query(
    String collection, {
    RemoteQuery? query,
  });

  Future<Map<String, Object?>> update(
    String collection,
    String id,
    Map<String, Object?> data,
  );

  Future<void> delete(String collection, String id);

  Stream<Map<String, Object?>?> watch(String collection, String id);
}
