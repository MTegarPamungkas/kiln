import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_config.dart';
import 'package:{{app_name}}/extensions/neon/neon_gateway.dart';
import 'package:{{app_name}}/extensions/neon/neon_storage_config.dart';
import 'package:{{app_name}}/extensions/neon/neon_storage_gateway.dart';

/// In-memory document store backing [FakePostgrestGateway].
final class FakeDocumentStore {
  final Map<String, Map<String, Map<String, Object?>>> tables =
      <String, Map<String, Map<String, Object?>>>{};

  int _nextId = 0;

  Map<String, Object?> insert(String table, Map<String, Object?> data) {
    final id = data['id']?.toString() ?? 'doc-${++_nextId}';
    final row = <String, Object?>{...data, 'id': id};
    tables.putIfAbsent(table, () => <String, Map<String, Object?>>{})[id] = row;
    return row;
  }

  Map<String, Object?>? read(String table, String id) => tables[table]?[id];

  Map<String, Object?>? update(
    String table,
    String id,
    Map<String, Object?> data,
  ) {
    final existing = tables[table]?[id];
    if (existing == null) {
      return null;
    }
    final row = <String, Object?>{...existing, ...data, 'id': id};
    tables[table]![id] = row;
    return row;
  }

  bool delete(String table, String id) {
    final bucket = tables[table];
    if (bucket == null || !bucket.containsKey(id)) {
      return false;
    }
    bucket.remove(id);
    return true;
  }

  List<Map<String, Object?>> select(String table, PostgrestQuery? query) {
    var rows = tables[table]?.values.toList() ?? <Map<String, Object?>>[];
    for (final filter in query?.filters ?? const <PostgrestFilter>[]) {
      rows = rows.where((row) => _matches(row, filter)).toList();
    }
    for (final order in query?.orderBy ?? const <PostgrestOrder>[]) {
      rows.sort((left, right) {
        final result = _compare(left[order.column], right[order.column]);
        return order.ascending ? result : -result;
      });
    }
    final offset = query?.offset ?? 0;
    if (offset > 0) {
      rows = rows.skip(offset).toList();
    }
    final limit = query?.limit;
    if (limit != null && rows.length > limit) {
      rows = rows.take(limit).toList();
    }
    return rows;
  }

  bool _matches(Map<String, Object?> row, PostgrestFilter filter) {
    final actual = row[filter.column];
    final expected = filter.value;
    switch (filter.operator) {
      case PostgrestOperator.equals:
        return actual == expected;
      case PostgrestOperator.notEquals:
        return actual != expected;
      case PostgrestOperator.greaterThan:
        return _compare(actual, expected) > 0;
      case PostgrestOperator.greaterThanOrEqual:
        return _compare(actual, expected) >= 0;
      case PostgrestOperator.lessThan:
        return _compare(actual, expected) < 0;
      case PostgrestOperator.lessThanOrEqual:
        return _compare(actual, expected) <= 0;
      case PostgrestOperator.inList:
        return expected is Iterable && expected.contains(actual);
      case PostgrestOperator.notInList:
        return expected is Iterable && !expected.contains(actual);
      case PostgrestOperator.contains:
        if (actual is Iterable) {
          return actual.contains(expected);
        }
        return actual == expected;
      case PostgrestOperator.isNull:
        return actual == null;
      case PostgrestOperator.isNotNull:
        return actual != null;
    }
  }

  int _compare(Object? left, Object? right) {
    if (left is Comparable &&
        right != null &&
        left.runtimeType == right.runtimeType) {
      return left.compareTo(right);
    }
    return '$left'.compareTo('$right');
  }
}

/// Fake PostgREST gateway on top of [FakeDocumentStore].
class FakePostgrestGateway implements PostgrestGateway {
  FakePostgrestGateway({FakeDocumentStore? store})
    : store = store ?? FakeDocumentStore();

  final FakeDocumentStore store;
  PostgrestQuery? lastQuery;
  int callCount = 0;

  /// Error thrown by the next operation, consumed once.
  Object? failure;

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> data,
  ) async {
    callCount += 1;
    _throwIfNeeded();
    return Map<String, Object?>.from(store.insert(table, data));
  }

  @override
  Future<Map<String, Object?>?> selectById(String table, String id) async {
    callCount += 1;
    _throwIfNeeded();
    final row = store.read(table, id);
    return row == null ? null : Map<String, Object?>.from(row);
  }

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    PostgrestQuery? query,
  }) async {
    callCount += 1;
    _throwIfNeeded();
    lastQuery = query;
    return store
        .select(table, query)
        .map<Map<String, Object?>>((row) => Map<String, Object?>.from(row))
        .toList(growable: false);
  }

  @override
  Future<Map<String, Object?>?> updateById(
    String table,
    String id,
    Map<String, Object?> data,
  ) async {
    callCount += 1;
    _throwIfNeeded();
    final row = store.update(table, id, data);
    return row == null ? null : Map<String, Object?>.from(row);
  }

  @override
  Future<bool> deleteById(String table, String id) async {
    callCount += 1;
    _throwIfNeeded();
    return store.delete(table, id);
  }

  void _throwIfNeeded() {
    final error = failure;
    if (error != null) {
      failure = null;
      throw error;
    }
  }
}

/// Configuration without any network access, with a fast poll for tests.
NeonConfig testConfig({Duration watchInterval = const Duration(milliseconds: 5)}) {
  return NeonConfig(
    dataApiUrl: 'https://demo.aws.neon.tech/sql/rest',
    apiKey: 'demo-token',
    watchInterval: watchInterval,
  );
}

/// Object Storage configuration used by the fake gateway (no network).
NeonStorageConfig testStorageConfig() {
  return const NeonStorageConfig(
    endpoint: 'https://demo.storage.c-us-east-2.aws.neon.tech',
    bucket: 'files',
    region: 'us-east-2',
    accessKeyId: 'token-id',
    secretAccessKey: 's3-secret',
  );
}

/// In-memory [NeonStorageGateway] for tests.
final class FakeNeonStorageGateway implements NeonStorageGateway {
  final Map<String, List<int>> files = <String, List<int>>{};
  final Map<String, String> contentTypes = <String, String>{};
  final List<String> uploadedPaths = <String>[];
  final List<String> deletedPaths = <String>[];

  /// Error thrown by the next call, consumed once.
  Object? failure;

  @override
  Future<void> upload(
    String key,
    List<int> bytes, {
    String? contentType,
    Map<String, String> metadata = const <String, String>{},
    bool upsert = false,
    ProgressCallback? onProgress,
  }) async {
    _throwIfNeeded();
    uploadedPaths.add(key);
    files[key] = List<int>.from(bytes);
    if (contentType != null) {
      contentTypes[key] = contentType;
    }
    onProgress?.call(1);
  }

  @override
  Future<List<int>> download(
    String key, {
    ProgressCallback? onProgress,
  }) async {
    _throwIfNeeded();
    final bytes = files[key];
    if (bytes == null) {
      throw const Failure(
        code: FailureCode.fileNotFound,
        message: 'The file was not found.',
        kind: FailureKind.storage,
      );
    }
    onProgress?.call(1);
    return List<int>.from(bytes);
  }

  @override
  Future<Uri> createSignedUrl(String key, Duration expiresIn) async {
    _throwIfNeeded();
    return Uri.parse(
      'https://storage.neon.test/$key?expires=${expiresIn.inSeconds}',
    );
  }

  @override
  Future<void> delete(String key) async {
    _throwIfNeeded();
    deletedPaths.add(key);
    if (files.remove(key) == null) {
      throw const Failure(
        code: FailureCode.fileNotFound,
        message: 'The file was not found.',
        kind: FailureKind.storage,
      );
    }
  }

  void _throwIfNeeded() {
    final error = failure;
    if (error != null) {
      failure = null;
      throw error;
    }
  }
}
