import 'package:kiln_core/kiln_core.dart';
import 'package:sembast/sembast.dart';

import 'collection_watcher.dart';
import 'local_db_failure_mapper.dart';
import 'query_builder.dart';

typedef LocalDatabaseOpener = Future<Database> Function();

/// [LocalDatabase] backed by Sembast.
final class SembastLocalDatabase implements LocalDatabase {
  SembastLocalDatabase({
    this.opener,
    this.database,
  });

  final LocalDatabaseOpener? opener;
  Database? database;
  Future<Database>? _opening;

  Future<Database> _db() {
    final existing = database;
    if (existing != null) {
      return Future<Database>.value(existing);
    }
    final opening = _opening;
    if (opening != null) {
      return opening;
    }
    final future = (opener ?? () async {
      throw StateError('No database opener configured');
    })().then<Database>((opened) {
      database = opened;
      return opened;
    });
    _opening = future;
    return future;
  }

  StoreRef<String, Map<String, Object?>> _store(String collection) {
    return stringMapStoreFactory.store(collection);
  }

  @override
  Future<void> put(
    String collection,
    String key,
    Map<String, Object?> data,
  ) async {
    try {
      final database = await _db();
      await _store(collection).record(key).put(
        database,
        Map<String, Object?>.of(data),
      );
    } catch (error, stackTrace) {
      throw mapLocalDbError(
        error,
        stackTrace: stackTrace,
        code: FailureCode.databaseUnavailable,
      );
    }
  }

  @override
  Future<Map<String, Object?>?> get(String collection, String key) async {
    try {
      final database = await _db();
      final data = await _store(collection).record(key).get(database);
      return data == null ? null : Map<String, Object?>.of(data);
    } catch (error, stackTrace) {
      throw mapLocalDbError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<List<LocalRecord>> query(
    String collection, {
    LocalQuery? query,
  }) async {
    try {
      final database = await _db();
      final finder = const LocalQueryBuilder().build(query);
      final snapshots = await _store(collection).find(
        database,
        finder: finder,
      );
      return const CollectionWatcher().toRecords(snapshots);
    } catch (error, stackTrace) {
      throw mapLocalDbError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> delete(String collection, String key) async {
    try {
      final database = await _db();
      await _store(collection).record(key).delete(database);
    } catch (error, stackTrace) {
      throw mapLocalDbError(error, stackTrace: stackTrace);
    }
  }

  @override
  Stream<List<LocalRecord>> watch(
    String collection, {
    LocalQuery? query,
  }) async* {
    final database = await _db();
    yield* const CollectionWatcher().watch(
      database: database,
      collection: collection,
      query: query,
    );
  }

  Future<T> transaction<T>(
    Future<T> Function(DatabaseClient client) action,
  ) async {
    final database = await _db();
    try {
      return await database.transaction(action);
    } catch (error, stackTrace) {
      throw mapLocalDbError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> close() async {
    final existing = database ?? await _opening;
    database = null;
    _opening = null;
    if (existing != null) {
      await existing.close();
    }
  }
}
