import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_realtime_gateway.dart';

import 'test_support.dart';

void main() {
  test('watch emits the current row, then realtime changes', () async {
    final database = FakeAppwriteDatabaseGateway();
    final created = await database.createRow('users', <String, Object?>{
      'name': 'First',
    });
    final rowId = '${created['id']}';
    final realtime = FakeRealtime();
    final gateway = SdkAppwriteRealtimeGateway(
      realtime: realtime,
      database: database,
      databaseId: 'database',
    );
    final received = <Map<String, Object?>?>[];
    final closed = Completer<void>();
    final subscription = gateway
        .watch(tableId: 'users', rowId: rowId)
        .listen(
          received.add,
          onDone: () {
            if (!closed.isCompleted) {
              closed.complete();
            }
          },
        );

    await pumpEventQueue();
    expect(received.first?['name'], 'First');
    expect(
      realtime.channels,
      contains('tablesdb.database.tables.users.rows.$rowId'),
    );

    realtime.emit(
      events: <String>['tablesdb.database.tables.users.rows.$rowId.update'],
      payload: <String, dynamic>{r'$id': rowId, 'name': 'Second'},
    );
    await pumpEventQueue();
    expect(received.last?['name'], 'Second');

    await gateway.dispose();

    await closed.future.timeout(const Duration(seconds: 1));
    expect(realtime.unsubscribed, isTrue);
    expect(
      () => gateway.watch(tableId: 'users', rowId: rowId),
      throwsA(isA<Failure>()),
    );
    await subscription.cancel();
  });

  test('a delete event emits null', () async {
    final database = FakeAppwriteDatabaseGateway();
    final created = await database.createRow('users', <String, Object?>{
      'name': 'First',
    });
    final rowId = '${created['id']}';
    final realtime = FakeRealtime();
    final gateway = SdkAppwriteRealtimeGateway(
      realtime: realtime,
      database: database,
      databaseId: 'database',
    );
    final received = <Map<String, Object?>?>[];
    final subscription = gateway
        .watch(tableId: 'users', rowId: rowId)
        .listen(received.add);
    await pumpEventQueue();

    realtime.emit(
      events: <String>['tablesdb.database.tables.users.rows.$rowId.delete'],
      payload: <String, dynamic>{r'$id': rowId},
    );
    await pumpEventQueue();

    expect(received.last, isNull);
    await subscription.cancel();
    await gateway.dispose();
  });
}

final class FakeRealtime implements Realtime {
  final List<String> channels = <String>[];
  bool unsubscribed = false;
  StreamController<RealtimeMessage>? _controller;

  void emit({
    required List<String> events,
    required Map<String, dynamic> payload,
  }) {
    _controller?.add(
      RealtimeMessage(
        events: events,
        payload: payload,
        channels: const <String>[],
        timestamp: '2026-01-01T00:00:00.000Z',
      ),
    );
  }

  @override
  Client get client => throw UnimplementedError('FakeRealtime has no client.');

  @override
  int? get closeCode => null;

  @override
  Future<void> disconnect() async {
    await _controller?.close();
  }

  @override
  RealtimeSubscription subscribe(
    List<Object> channels, {
    List<String> queries = const <String>[],
  }) {
    this.channels.addAll(channels.map((channel) => '$channel'));
    final controller = StreamController<RealtimeMessage>.broadcast();
    _controller = controller;
    return RealtimeSubscription(
      close: () async {
        unsubscribed = true;
        await controller.close();
      },
      unsubscribe: () async {
        unsubscribed = true;
        await controller.close();
      },
      update: ({List<Object>? channels, List<String>? queries}) async {},
      channels: channels.map((channel) => '$channel').toList(growable: false),
      queries: queries,
      controller: controller,
    );
  }

  @override
  void upsertPresence({
    required String status,
    required String presenceId,
    List<String>? permissions,
    Map<String, dynamic>? metadata,
  }) {}
}
