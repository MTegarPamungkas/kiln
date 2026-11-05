import 'package:kiln_core/kiln_core.dart';

/// One pending change waiting to be sent to a RemoteDatabase.
final class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.collection,
    required this.key,
    required this.operation,
    required this.data,
    required this.createdAt,
  });

  final String id;
  final String collection;
  final String key;
  final String operation;
  final Map<String, Object?> data;
  final DateTime createdAt;
}

/// Stores local changes so they can be replayed when the network returns.
final class SyncQueue {
  SyncQueue({
    required this.database,
    this.collection = '_sync_queue',
    Clock? clock,
  }) : _clock = clock ?? const SystemClock();

  final LocalDatabase database;
  final String collection;
  final Clock _clock;
  int _sequence = 0;

  Future<String> enqueue(
    String collection,
    String key,
    Map<String, Object?> data, {
    String operation = 'upsert',
  }) async {
    final id =
        '${_clock.now().toUtc().microsecondsSinceEpoch}-${_sequence++}';
    await database.put(this.collection, id, <String, Object?>{
      'collection': collection,
      'key': key,
      'operation': operation,
      'data': data,
      'createdAt': _clock.now().toUtc().toIso8601String(),
    });
    return id;
  }

  Future<List<SyncQueueItem>> pending() async {
    final records = await database.query(
      collection,
      query: const LocalQuery(orderBy: 'createdAt'),
    );
    return <SyncQueueItem>[
      for (final record in records)
        SyncQueueItem(
          id: record.key,
          collection: '${record.data['collection']}',
          key: '${record.data['key']}',
          operation: '${record.data['operation']}',
          data: Map<String, Object?>.from(
            record.data['data'] as Map? ?? const <String, Object?>{},
          ),
          createdAt:
              DateTime.tryParse('${record.data['createdAt']}') ??
              _clock.now().toUtc(),
        ),
    ];
  }

  Future<void> remove(String id) => database.delete(collection, id);

  Future<int> flush(
    Future<void> Function(SyncQueueItem item) handler,
  ) async {
    final items = await pending();
    var count = 0;
    for (final item in items) {
      await handler(item);
      await remove(item.id);
      count++;
    }
    return count;
  }
}
