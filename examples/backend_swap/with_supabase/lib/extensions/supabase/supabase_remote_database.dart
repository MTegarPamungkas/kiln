// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'postgrest_gateway.dart';
import 'supabase_failure_mapper.dart';
import 'supabase_query_mapper.dart';
import 'supabase_realtime_gateway.dart';

/// [RemoteDatabase] implementation on top of PostgREST and Supabase realtime.
///
/// Every document uses the `id` column as its key. Operations that touch a
/// missing document throw `Failure(remote_database.not_found)`.
final class SupabaseRemoteDatabase implements RemoteDatabase {
  SupabaseRemoteDatabase({
    required PostgrestGateway postgrest,
    required SupabaseRealtimeGateway realtime,
    SupabaseQueryMapper mapper = const SupabaseQueryMapper(),
  }) : _postgrest = postgrest,
       _realtime = realtime,
       _mapper = mapper;

  final PostgrestGateway _postgrest;
  final SupabaseRealtimeGateway _realtime;
  final SupabaseQueryMapper _mapper;

  @override
  Future<Map<String, Object?>> create(
    String collection,
    Map<String, Object?> data,
  ) async {
    _validateCollection(collection);
    final row = await _call(
      () => _postgrest.insert(collection, data),
      FailureCode.remoteDatabaseUnavailable,
    );
    if (!row.containsKey('id')) {
      throw const Failure(
        code: FailureCode.remoteDatabaseQueryFailed,
        message: 'Tabel tujuan tidak mengembalikan kolom id.',
        kind: FailureKind.database,
      );
    }
    return row;
  }

  @override
  Future<Map<String, Object?>?> read(String collection, String id) async {
    _validateCollection(collection);
    _validateId(id);
    return _call(
      () => _postgrest.selectById(collection, id),
      FailureCode.remoteDatabaseQueryFailed,
    );
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String collection, {
    RemoteQuery? query,
  }) async {
    _validateCollection(collection);
    final mapped = _mapper.toPostgrest(query);
    return _call(
      () => _postgrest.select(collection, query: mapped),
      FailureCode.remoteDatabaseQueryFailed,
    );
  }

  @override
  Future<Map<String, Object?>> update(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async {
    _validateCollection(collection);
    _validateId(id);
    final row = await _call(
      () => _postgrest.updateById(collection, id, data),
      FailureCode.remoteDatabaseUnavailable,
    );
    if (row == null) {
      throw _notFound(collection, id);
    }
    return row;
  }

  @override
  Future<void> delete(String collection, String id) async {
    _validateCollection(collection);
    _validateId(id);
    final deleted = await _call(
      () => _postgrest.deleteById(collection, id),
      FailureCode.remoteDatabaseUnavailable,
    );
    if (!deleted) {
      throw _notFound(collection, id);
    }
  }

  @override
  Stream<Map<String, Object?>?> watch(String collection, String id) {
    _validateCollection(collection);
    _validateId(id);
    final controller = StreamController<Map<String, Object?>?>();
    final pendingChanges = <Map<String, Object?>?>[];
    StreamSubscription<Map<String, Object?>?>? changes;
    var emittingChanges = false;
    var cancelled = false;

    void emitChange(Map<String, Object?>? row) {
      if (cancelled || controller.isClosed) {
        return;
      }
      if (emittingChanges) {
        controller.add(row);
      } else {
        pendingChanges.add(row);
      }
    }

    controller.onListen = () async {
      changes = _realtime
          .watchRow(collection, id)
          .listen(
            emitChange,
            onError: (Object error, StackTrace stackTrace) {
              if (cancelled || controller.isClosed) {
                return;
              }
              controller.addError(
                mapSupabaseError(
                  error,
                  stackTrace: stackTrace,
                  fallbackCode: FailureCode.remoteDatabaseUnavailable,
                  fallbackKind: FailureKind.network,
                ),
                stackTrace,
              );
            },
          );
      try {
        final current = await read(collection, id);
        if (cancelled || controller.isClosed) {
          return;
        }
        controller.add(current);
        emittingChanges = true;
        for (final row in pendingChanges) {
          controller.add(row);
        }
        pendingChanges.clear();
      } on Object catch (error, stackTrace) {
        await changes?.cancel();
        changes = null;
        if (!cancelled && !controller.isClosed) {
          controller.addError(error, stackTrace);
          await controller.close();
        }
      }
    };

    controller.onCancel = () async {
      cancelled = true;
      pendingChanges.clear();
      await changes?.cancel();
      changes = null;
      await controller.close();
    };

    return controller.stream;
  }

  void _validateCollection(String collection) {
    _mapper.validateIdentifier(collection, label: 'tabel');
  }

  void _validateId(String id) {
    if (id.trim().isEmpty) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'Id dokumen tidak boleh kosong.',
        kind: FailureKind.validation,
      );
    }
  }

  Failure _notFound(String collection, String id) {
    return Failure(
      code: FailureCode.remoteDatabaseNotFound,
      message: 'Dokumen "$id" tidak ada di "$collection".',
      kind: FailureKind.database,
      details: <String, Object?>{'collection': collection, 'id': id},
    );
  }

  Future<T> _call<T>(
    Future<T> Function() action,
    FailureCode fallbackCode,
  ) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(
        error,
        stackTrace: stackTrace,
        fallbackCode: fallbackCode,
        fallbackKind: FailureKind.database,
      );
    }
  }
}
