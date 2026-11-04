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
    this.cursor,
  });

  final List<RemoteFilter> filters;
  final List<RemoteOrder> orderBy;
  final int? limit;
  final int offset;

  /// Opaque cursor returned by a previous [RemotePage.nextCursor].
  ///
  /// Cursor pagination is preferred over [offset] when the backend supports it
  /// because it stays stable while rows are inserted or removed.
  final String? cursor;
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

/// One page of a [RemoteQuery] result set.
final class RemotePage<T> {
  const RemotePage({
    required this.items,
    this.nextCursor,
    this.nextOffset,
    this.totalCount,
  });

  final List<T> items;

  /// Opaque token to request the following page, when cursor pagination is
  /// used. Pass it back as [RemoteQuery.cursor].
  final String? nextCursor;

  /// Offset of the following page when offset pagination is used.
  final int? nextOffset;

  /// Total number of rows across all pages, when the backend knows it.
  final int? totalCount;

  bool get hasMore => nextCursor != null || nextOffset != null;
}

/// [RemoteDatabase] backends that can return results one page at a time.
abstract interface class PaginatedRemoteDatabase implements RemoteDatabase {
  Future<RemotePage<Map<String, Object?>>> queryPage(
    String collection, {
    RemoteQuery? query,
  });
}

/// The operation applied by one [RemoteWrite].
enum RemoteWriteKind { insert, update, delete }

/// One operation in a batch write.
final class RemoteWrite {
  const RemoteWrite(this.kind, this.data, {this.id});

  const RemoteWrite.insert(Map<String, Object?> data)
    : this(RemoteWriteKind.insert, data);

  const RemoteWrite.update(String id, Map<String, Object?> data)
    : this(RemoteWriteKind.update, data, id: id);

  const RemoteWrite.delete(String id)
    : this(RemoteWriteKind.delete, const <String, Object?>{}, id: id);

  final RemoteWriteKind kind;
  final Map<String, Object?> data;

  /// Document id for [RemoteWriteKind.update] and [RemoteWriteKind.delete].
  final String? id;
}

/// [RemoteDatabase] backends that can apply several writes together.
abstract interface class BatchRemoteDatabase implements RemoteDatabase {
  /// Applies every write against [collection].
  ///
  /// Implementations should apply the writes atomically when the backend
  /// supports transactions, and may fail the whole batch on the first error.
  Future<void> writeBatch(String collection, List<RemoteWrite> writes);
}

/// Convenience helpers for [BatchRemoteDatabase] built on single-document
/// operations, so apps do not have to assemble [RemoteWrite] lists by hand.
extension BatchRemoteDatabaseX on BatchRemoteDatabase {
  Future<List<Map<String, Object?>>> createMany(
    String collection,
    List<Map<String, Object?>> documents,
  ) async {
    final results = <Map<String, Object?>>[];
    for (final document in documents) {
      results.add(await create(collection, document));
    }
    return results;
  }

  Future<void> updateMany(
    String collection,
    Map<String, Map<String, Object?>> updates,
  ) async {
    for (final entry in updates.entries) {
      await update(collection, entry.key, entry.value);
    }
  }

  Future<void> deleteMany(String collection, Iterable<String> ids) async {
    for (final id in ids) {
      await delete(collection, id);
    }
  }
}
