import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'appwrite_database_gateway.dart';
import 'appwrite_failure_mapper.dart';
import 'appwrite_query_mapper.dart';
import 'appwrite_realtime_gateway.dart';

/// [RemoteDatabase] on top of the Appwrite TablesDB and realtime services.
///
/// The [collection] argument is the Appwrite table id. Documents returned to
/// callers contain the Appwrite row id under `id` plus every stored column.
final class AppwriteRemoteDatabase implements RemoteDatabase {
  AppwriteRemoteDatabase({
    required this.gateway,
    required this.realtime,
    this.queryMapper = const AppwriteQueryMapper(),
    AppwriteFailureMapper failureMapper = const AppwriteFailureMapper(),
  }) : _failures = failureMapper;

  final AppwriteDatabaseGateway gateway;
  final AppwriteRealtimeGateway realtime;
  final AppwriteQueryMapper queryMapper;
  final AppwriteFailureMapper _failures;

  @override
  Future<Map<String, Object?>> create(
    String collection,
    Map<String, Object?> data,
  ) {
    return _guard(() => gateway.createRow(collection, data));
  }

  @override
  Future<Map<String, Object?>?> read(String collection, String id) async {
    try {
      return await gateway.getRow(collection, id);
    } on Object catch (error, stackTrace) {
      final failure = _failures.map(
        error,
        scope: AppwriteFailureScope.database,
        stackTrace: stackTrace,
      );
      if (failure.code == FailureCode.remoteDatabaseNotFound) {
        return null;
      }
      throw failure;
    }
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String collection, {
    RemoteQuery? query,
  }) {
    return _guard(() {
      final queries = queryMapper.map(query);
      return gateway.listRows(collection, queries: queries);
    });
  }

  @override
  Future<Map<String, Object?>> update(
    String collection,
    String id,
    Map<String, Object?> data,
  ) {
    return _guard(() => gateway.updateRow(collection, id, data));
  }

  @override
  Future<void> delete(String collection, String id) {
    return _guard(() => gateway.deleteRow(collection, id));
  }

  @override
  Stream<Map<String, Object?>?> watch(String collection, String id) {
    return realtime
        .watch(tableId: collection, rowId: id)
        .transform(
          StreamTransformer<
            Map<String, Object?>?,
            Map<String, Object?>?
          >.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(
                _failures.map(
                  error,
                  scope: AppwriteFailureScope.database,
                  stackTrace: stackTrace,
                ),
                stackTrace,
              );
            },
          ),
        );
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on Object catch (error, stackTrace) {
      throw _failures.map(
        error,
        scope: AppwriteFailureScope.database,
        stackTrace: stackTrace,
      );
    }
  }
}
