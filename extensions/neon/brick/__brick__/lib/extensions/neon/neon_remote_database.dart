// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

import 'neon_change_signal.dart';
import 'neon_config.dart';
import 'neon_failure_mapper.dart';
import 'neon_gateway.dart';
import 'neon_query_mapper.dart';

/// [RemoteDatabase] implementation on top of the Neon Data API (PostgREST).
///
/// Every document uses the `id` column as its key. Operations that touch a
/// missing document throw `Failure(remote_database.notFound)`.
///
/// The Data API is request/response only, so [watch] polls the row on a timer
/// and emits whenever its content changes. When a [NeonChangeSignal] is
/// supplied, a matching hint re-polls the row immediately — turn the interval
/// into a backstop and let an out-of-band push channel (FCM, socket, webhook
/// relay) carry the freshness.
final class NeonRemoteDatabase implements RemoteDatabase {
  NeonRemoteDatabase({
    required PostgrestGateway gateway,
    required NeonConfig config,
    NeonQueryMapper mapper = const NeonQueryMapper(),
    NeonChangeSignal? changeSignal,
  }) : _gateway = gateway,
       _config = config,
       _mapper = mapper,
       _changeSignal = changeSignal;

  final PostgrestGateway _gateway;
  final NeonConfig _config;
  final NeonQueryMapper _mapper;
  final NeonChangeSignal? _changeSignal;

  @override
  Future<Map<String, Object?>> create(
    String collection,
    Map<String, Object?> data,
  ) async {
    _validateCollection(collection);
    final row = await _call(
      () => _gateway.insert(collection, data),
      FailureCode.remoteDatabaseUnavailable,
    );
    if (!row.containsKey('id')) {
      throw const Failure(
        code: FailureCode.remoteDatabaseQueryFailed,
        message: 'The target table did not return an id column.',
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
      () => _gateway.selectById(collection, id),
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
      () => _gateway.select(collection, query: mapped),
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
      () => _gateway.updateById(collection, id, data),
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
      () => _gateway.deleteById(collection, id),
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
    Timer? timer;
    StreamSubscription<NeonChangeHint>? signalSubscription;
    var cancelled = false;
    var polling = false;
    String? lastSignature;

    Future<void> poll({required bool initial}) async {
      if (cancelled || polling) {
        return;
      }
      polling = true;
      try {
        final row = await read(collection, id);
        polling = false;
        if (cancelled || controller.isClosed) {
          return;
        }
        final signature = _signature(row);
        if (initial || signature != lastSignature) {
          lastSignature = signature;
          controller.add(row);
        }
      } on Object catch (error, stackTrace) {
        polling = false;
        if (cancelled || controller.isClosed) {
          return;
        }
        final failure = mapNeonError(
          error,
          stackTrace: stackTrace,
          fallbackCode: FailureCode.remoteDatabaseQueryFailed,
        );
        if (initial) {
          timer?.cancel();
          controller
            ..addError(failure, stackTrace)
            ..close();
        } else {
          controller.addError(failure, stackTrace);
        }
      }
    }

    controller.onListen = () async {
      final signal = _changeSignal;
      if (signal != null) {
        signalSubscription = signal.changes.listen(
          (hint) {
            if (cancelled || controller.isClosed) {
              return;
            }
            if (!_hintMatches(hint, collection, id)) {
              return;
            }
            // The polling guard coalesces hints that arrive mid-poll.
            unawaited(poll(initial: false));
          },
          onError: (Object _) {
            // The signal is best-effort; the interval timer keeps the watch
            // fresh when a hint is missed.
          },
        );
      }
      await poll(initial: true);
      if (cancelled || controller.isClosed) {
        return;
      }
      timer = Timer.periodic(
        _config.watchInterval,
        (_) => unawaited(poll(initial: false)),
      );
    };

    controller.onCancel = () async {
      cancelled = true;
      timer?.cancel();
      timer = null;
      await signalSubscription?.cancel();
      signalSubscription = null;
      await controller.close();
    };

    return controller.stream;
  }

  /// Whether [hint] concerns the watched [collection] row [id]. A null side
  /// means "any", so app channels can emit coarse or precise hints.
  bool _hintMatches(NeonChangeHint hint, String collection, String id) {
    final table = hint.table;
    if (table != null && table != collection) {
      return false;
    }
    final rowId = hint.id;
    return rowId == null || rowId == id;
  }

  void _validateCollection(String collection) {
    _mapper.validateIdentifier(collection, label: 'table');
  }

  void _validateId(String id) {
    if (id.trim().isEmpty) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'The document id cannot be empty.',
        kind: FailureKind.validation,
      );
    }
  }

  Failure _notFound(String collection, String id) {
    return Failure(
      code: FailureCode.remoteDatabaseNotFound,
      message: 'Document "$id" does not exist in "$collection".',
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
      throw mapNeonError(
        error,
        stackTrace: stackTrace,
        fallbackCode: fallbackCode,
        fallbackKind: FailureKind.database,
      );
    }
  }

  /// Order-independent content signature so a poll only emits on a real change.
  String _signature(Map<String, Object?>? row) {
    if (row == null) {
      return 'null';
    }
    final keys = row.keys.toList()..sort();
    return jsonEncode(<String, Object?>{
      for (final key in keys) key: row[key],
    });
  }
}
