import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:kiln_core/kiln_core.dart';

import 'appwrite_database_gateway.dart';

/// Realtime document subscriptions that can be replaced with a fake.
abstract interface class AppwriteRealtimeGateway {
  /// Emits the current document, then every later change for the row.
  ///
  /// A deleted document is emitted as null.
  Stream<Map<String, Object?>?> watch({
    required String tableId,
    required String rowId,
  });

  /// Cancels every subscription and closes every open stream.
  Future<void> dispose();
}

/// [AppwriteRealtimeGateway] backed by the Appwrite `Realtime` service.
final class SdkAppwriteRealtimeGateway implements AppwriteRealtimeGateway {
  SdkAppwriteRealtimeGateway({
    required this.realtime,
    required this.database,
    required this.databaseId,
    this.reconcileDelay = const Duration(milliseconds: 1500),
  });

  final Realtime realtime;
  final AppwriteDatabaseGateway database;
  final String databaseId;

  /// How long after subscribing the reconciliation read runs. Events
  /// published while Appwrite is still registering the channel are dropped
  /// server-side, so one delayed read lets the stream converge on the row's
  /// real state.
  final Duration reconcileDelay;
  final Map<StreamController<Map<String, Object?>?>, _Watch> _watches =
      <StreamController<Map<String, Object?>?>, _Watch>{};
  bool _disposed = false;

  @override
  Stream<Map<String, Object?>?> watch({
    required String tableId,
    required String rowId,
  }) {
    if (_disposed) {
      throw const Failure(
        code: FailureCode.unavailable,
        message: 'The Appwrite realtime gateway is disposed.',
        kind: FailureKind.unavailable,
      );
    }

    final controller = StreamController<Map<String, Object?>?>.broadcast();
    final buffered = <Map<String, Object?>?>[];
    var live = false;
    Map<String, Object?>? lastEmitted;
    void emit(Map<String, Object?>? document) {
      if (_sameDocument(document, lastEmitted)) {
        return;
      }
      lastEmitted = document;
      if (!controller.isClosed) {
        controller.add(document);
      }
    }

    final subscription = realtime.subscribe(<Object>[
      Channel.tablesdb(databaseId).table(tableId).row(rowId).toString(),
    ]);
    final listener = subscription.stream.listen(
      (message) {
        final document = _fromMessage(message, rowId);
        if (live) {
          emit(document);
        } else {
          buffered.add(document);
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    final reconcile = Timer(reconcileDelay, () {
      unawaited(_reconcile(controller: controller, tableId: tableId, rowId: rowId, emit: emit));
    });

    _watches[controller] = _Watch(
      subscription: subscription,
      listener: listener,
      controller: controller,
      reconcile: reconcile,
    );
    unawaited(
      _emitCurrent(
        controller: controller,
        tableId: tableId,
        rowId: rowId,
        buffered: buffered,
        emit: emit,
        goLive: () => live = true,
      ),
    );
    return controller.stream;
  }

  Future<void> _emitCurrent({
    required StreamController<Map<String, Object?>?> controller,
    required String tableId,
    required String rowId,
    required List<Map<String, Object?>?> buffered,
    required void Function(Map<String, Object?>?) emit,
    required void Function() goLive,
  }) async {
    try {
      final current = await database.getRow(tableId, rowId);
      emit(current);
    } on Object catch (error, stackTrace) {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    }
    goLive();
    for (final document in buffered) {
      emit(document);
    }
    buffered.clear();
  }

  Future<void> _reconcile({
    required StreamController<Map<String, Object?>?> controller,
    required String tableId,
    required String rowId,
    required void Function(Map<String, Object?>?) emit,
  }) async {
    if (_disposed || controller.isClosed) {
      return;
    }
    try {
      emit(await database.getRow(tableId, rowId));
    } on Object {
      // Realtime events remain the source of truth; a failed reconciliation
      // read must not break the stream.
    }
  }

  bool _sameDocument(
    Map<String, Object?>? left,
    Map<String, Object?>? right,
  ) {
    if (identical(left, right)) {
      return true;
    }
    if (left == null || right == null || left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  Map<String, Object?>? _fromMessage(RealtimeMessage message, String rowId) {
    if (message.events.any((event) => event.endsWith('.delete'))) {
      return null;
    }
    final document = <String, Object?>{};
    for (final entry in message.payload.entries) {
      if (!entry.key.startsWith(r'$')) {
        document[entry.key] = entry.value;
      }
    }
    final id = message.payload[r'$id'];
    document['id'] = id is String && id.isNotEmpty ? id : rowId;
    return document;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final watches = _watches.values.toList(growable: false);
    _watches.clear();
    for (final watch in watches) {
      watch.reconcile.cancel();
      try {
        await watch.listener.cancel();
      } on Object {
        // A socket that is already gone must not hide later cleanup.
      }
      try {
        await watch.subscription.unsubscribe();
      } on Object {
        // The server may have closed the subscription first.
      }
      if (!watch.controller.isClosed) {
        await watch.controller.close();
      }
    }
  }
}

final class _Watch {
  const _Watch({
    required this.subscription,
    required this.listener,
    required this.controller,
    required this.reconcile,
  });

  final RealtimeSubscription subscription;
  final StreamSubscription<RealtimeMessage> listener;
  final StreamController<Map<String, Object?>?> controller;
  final Timer reconcile;
}
