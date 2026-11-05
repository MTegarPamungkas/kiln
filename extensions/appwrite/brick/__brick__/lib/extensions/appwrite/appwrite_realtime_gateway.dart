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
  });

  final Realtime realtime;
  final AppwriteDatabaseGateway database;
  final String databaseId;
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
    final subscription = realtime.subscribe(<Object>[
      Channel.tablesdb(databaseId).table(tableId).row(rowId).toString(),
    ]);
    final listener = subscription.stream.listen(
      (message) {
        final document = _fromMessage(message, rowId);
        if (live) {
          controller.add(document);
        } else {
          buffered.add(document);
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    _watches[controller] = _Watch(
      subscription: subscription,
      listener: listener,
      controller: controller,
    );
    unawaited(
      _emitCurrent(
        controller: controller,
        tableId: tableId,
        rowId: rowId,
        buffered: buffered,
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
    required void Function() goLive,
  }) async {
    try {
      final current = await database.getRow(tableId, rowId);
      if (!controller.isClosed) {
        controller.add(current);
      }
    } on Object catch (error, stackTrace) {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    }
    goLive();
    for (final document in buffered) {
      if (!controller.isClosed) {
        controller.add(document);
      }
    }
    buffered.clear();
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
  });

  final RealtimeSubscription subscription;
  final StreamSubscription<RealtimeMessage> listener;
  final StreamController<Map<String, Object?>?> controller;
}
