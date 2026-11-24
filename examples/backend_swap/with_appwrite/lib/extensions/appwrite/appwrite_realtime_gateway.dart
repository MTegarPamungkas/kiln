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

  /// How long after the initial read the reconciliation read runs. Events
  /// published while Appwrite is still registering the channel are dropped
  /// server-side, so one delayed read lets the stream converge on the row's
  /// real state.
  final Duration reconcileDelay;
  final Set<Future<void> Function()> _watches = {};
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

    late final StreamController<Map<String, Object?>?> controller;
    RealtimeSubscription? subscription;
    StreamSubscription<RealtimeMessage>? listener;
    Timer? reconcile;
    Future<void>? cleanup;
    var stopped = false;
    var started = false;
    var emitted = false;
    var revision = 0;
    Map<String, Object?>? lastEmitted;
    void emit(Map<String, Object?>? document) {
      if (stopped || (emitted && _sameDocument(document, lastEmitted))) {
        return;
      }
      emitted = true;
      lastEmitted = document;
      if (!controller.isClosed) {
        controller.add(document);
      }
    }

    Future<void> stop() {
      return cleanup ??= () async {
        stopped = true;
        reconcile?.cancel();
        try {
          await listener?.cancel();
        } on Object {
          // Continue cleanup after a socket failure.
        }
        try {
          await subscription?.unsubscribe();
        } on Object {
          // The server may have already removed the subscription.
        }
        // Do not await close here: paused listeners must not block disposal.
        unawaited(controller.close());
        _watches.remove(stop);
      }();
    }

    Future<void> readCurrent({required bool initial}) async {
      final readRevision = ++revision;
      try {
        final current = await database.getRow(tableId, rowId);
        // An event or newer read wins over an older HTTP response.
        if (!stopped && readRevision == revision) {
          revision++;
          emit(current);
        }
      } on Object catch (error, stackTrace) {
        if (initial && !stopped && readRevision == revision) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<Map<String, Object?>?>.broadcast(
      onListen: () {
        if (started || stopped) return;
        started = true;
        if (_disposed) {
          controller.addError(
            const Failure(
              code: FailureCode.unavailable,
              message: 'The Appwrite realtime gateway is disposed.',
              kind: FailureKind.unavailable,
            ),
          );
          unawaited(stop());
          return;
        }
        _watches.add(stop);
        try {
          subscription = realtime.subscribe(<Object>[
            Channel.tablesdb(databaseId).table(tableId).row(rowId).toString(),
          ]);
          listener = subscription!.stream.listen(
            (message) {
              revision++;
              emit(_fromMessage(message, rowId));
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!stopped) controller.addError(error, stackTrace);
            },
            onDone: () => unawaited(stop()),
          );
          unawaited(
            readCurrent(initial: true).whenComplete(() {
              if (!stopped) {
                reconcile = Timer(reconcileDelay, () {
                  unawaited(readCurrent(initial: false));
                });
              }
            }),
          );
        } on Object catch (error, stackTrace) {
          controller.addError(error, stackTrace);
          unawaited(stop());
        }
      },
      onCancel: () => unawaited(stop()),
    );
    return controller.stream;
  }

  bool _sameDocument(Map<String, Object?>? left, Map<String, Object?>? right) {
    if (identical(left, right)) {
      return true;
    }
    if (left == null || right == null || left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) ||
          !_sameValue(right[entry.key], entry.value)) {
        return false;
      }
    }
    return true;
  }

  bool _sameValue(Object? left, Object? right) {
    if (left is Map<String, Object?> && right is Map<String, Object?>) {
      return _sameDocument(left, right);
    }
    if (left is List && right is List) {
      return left.length == right.length &&
          List.generate(
            left.length,
            (index) => index,
          ).every((index) => _sameValue(left[index], right[index]));
    }
    return left == right;
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
    final watches = _watches.toList(growable: false);
    _watches.clear();
    for (final watch in watches) {
      await watch();
    }
  }
}
