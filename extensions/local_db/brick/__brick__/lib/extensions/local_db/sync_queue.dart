import 'dart:math';

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
    this.owner,
    this.claimId,
    this.claimedAt,
    this.attempts = 0,
    this.status = 'pending',
    this.nextAttemptAt,
    this.lastError,
  });

  final String id;
  final String collection;
  final String key;
  final String operation;
  final Map<String, Object?> data;
  final DateTime createdAt;

  /// Session or user that created the item, when the app scoped it.
  final String? owner;

  /// Identifier of the flush currently holding this item, or null.
  final String? claimId;

  /// When [claimId] was taken. A claim older than the queue's lease may be
  /// taken over by another flush.
  final DateTime? claimedAt;

  /// How many times a flush has claimed this item.
  final int attempts;

  /// Delivery state (`pending` or `dead_letter`).
  final String status;

  /// Earliest UTC timestamp for the next retry attempt, or null when ready now.
  final DateTime? nextAttemptAt;

  /// Last error recorded when delivery failed, if any.
  final String? lastError;

  bool get isDeadLetter => status == 'dead_letter';
}

/// Stores local changes so they can be replayed when the network returns.
///
/// Delivery is at-least-once: an item is removed only after the handler
/// succeeds, so a process death between the remote effect and the removal
/// replays it. Handlers must therefore use [SyncQueueItem.id] as a stable
/// idempotency key and treat a repeated id as already applied.
///
/// A flush is serialized across queues sharing the same database object and
/// collection in this isolate. When more than one isolate, engine or process can
/// open the same database, pass a [MutationLock] (for example the `local_db`
/// extension's `localDatabaseMutationLock`) so only one of them delivers at a
/// time.
///
/// Every item is also claimed durably before it is delivered: the claim carries
/// the flush id and a timestamp, so a second handle skips an item another flush
/// is working on, and a claim left behind by a crash expires after [claimLease]
/// and can be taken over. The lock remains the exclusion; the claim is what
/// survives a crash and makes in-flight work observable.
/// Items can be scoped to an owner (for example the signed-in user) so a
/// user switch does not replay another user's queue.
final class SyncQueue {
  SyncQueue({
    required this.database,
    this.collection = '_sync_queue',
    this.lock,
    this.claimLease = const Duration(minutes: 2),
    this.maxAttempts = 5,
    this.initialBackoff = Duration.zero,
    this.maxBackoff = const Duration(minutes: 5),
    Clock? clock,
  }) : assert(maxAttempts > 0),
       _clock = clock ?? const SystemClock();

  final LocalDatabase database;
  final String collection;

  /// Optional cross-handle/process exclusion held for a whole flush.
  final MutationLock? lock;

  /// How long a durable claim stays authoritative before another flush may
  /// take the item over.
  final Duration claimLease;

  /// Maximum delivery attempts before an item moves to `dead_letter` so it
  /// cannot permanently block later items in the queue.
  final int maxAttempts;

  /// Base exponential backoff applied after a failed attempt.
  final Duration initialBackoff;

  /// Upper cap for per-item exponential backoff.
  final Duration maxBackoff;
  final Clock _clock;
  final String _instanceId = _newInstanceId();
  int _sequence = 0;
  static final Expando<Map<String, Future<void>>> _tails =
      Expando<Map<String, Future<void>>>();

  static String _newInstanceId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<String> enqueue(
    String collection,
    String key,
    Map<String, Object?> data, {
    String operation = 'upsert',
    String? owner,
  }) async {
    final id =
        '${_clock.now().toUtc().microsecondsSinceEpoch}-$_instanceId-${_sequence++}';
    await database.put(this.collection, id, <String, Object?>{
      'collection': collection,
      'key': key,
      'operation': operation,
      'data': data,
      'createdAt': _clock.now().toUtc().toIso8601String(),
      'owner': ?owner,
    });
    return id;
  }

  /// Pending items in creation order, including items another flush has claimed.
  ///
  /// With no [owner], returns only unowned items. Administrative inspection can
  /// explicitly request [allOwners]; delivery never defaults to all owners.
  Future<List<SyncQueueItem>> pending({
    String? owner,
    bool allOwners = false,
    bool includeDeadLetter = false,
    int? limit,
  }) async {
    final where = <String, Object?>{
      if (!allOwners && owner != null) 'owner': owner,
    };
    final records = await database.query(
      collection,
      query: LocalQuery(
        where: where.isEmpty ? null : where,
        orderBy: 'createdAt',
        limit: (allOwners || owner != null) && includeDeadLetter ? limit : null,
      ),
    );
    final items = <SyncQueueItem>[];
    for (final record in records) {
      final item = _itemFrom(record.data, record.key);
      if (!allOwners && item.owner != owner) {
        continue;
      }
      if (!includeDeadLetter && item.isDeadLetter) {
        continue;
      }
      items.add(item);
      if (limit != null && items.length >= limit) {
        break;
      }
    }
    return items;
  }

  /// Items that exhausted [maxAttempts] and were moved out of active delivery.
  Future<List<SyncQueueItem>> deadLetters({
    String? owner,
    bool allOwners = false,
  }) async {
    final all = await pending(
      owner: owner,
      allOwners: allOwners,
      includeDeadLetter: true,
    );
    return all.where((item) => item.isDeadLetter).toList(growable: false);
  }

  Future<void> remove(String id) => database.delete(collection, id);

  /// Delivers pending items through [handler], one serialized flush at a time.
  ///
  /// A concurrent caller waits for the current flush and then finds no
  /// remaining items, so it returns zero. A handler error stops the flush and
  /// leaves that item (and the rest) pending for the next attempt. With a
  /// [lock], the whole flush holds it, so another isolate/process cannot deliver
  /// the same items concurrently.
  Future<int> flush(
    Future<void> Function(SyncQueueItem item) handler, {
    String? owner,
    SessionController? session,
  }) {
    final flushId = '$_instanceId-${_sequence++}';
    final guard = lock;
    if (guard == null) {
      return _serializedFlush(handler, owner, session, flushId);
    }
    return guard.runExclusive(
      () => _serializedFlush(handler, owner, session, flushId),
    );
  }

  Future<int> _serializedFlush(
    Future<void> Function(SyncQueueItem item) handler,
    String? owner,
    SessionController? session,
    String flushId,
  ) {
    final tails = _tails[database] ??= <String, Future<void>>{};
    final result = (tails[collection] ?? Future<void>.value()).then(
      (_) => _flushOnce(handler, owner, session, flushId),
    );
    tails[collection] = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<int> _flushOnce(
    Future<void> Function(SyncQueueItem item) handler,
    String? owner,
    SessionController? session,
    String flushId,
  ) async {
    final sessionOwner = session?.session?.userId;
    if (session != null &&
        (session.status != SessionStatus.authenticated ||
            sessionOwner == null ||
            (owner != null && owner != sessionOwner))) {
      return 0;
    }
    var sessionChanged = false;
    final subscription = session?.changes.listen((_) {
      sessionChanged = true;
    });
    try {
      final items = await pending(owner: owner ?? sessionOwner);
      var count = 0;
      for (final item in items) {
        if (sessionChanged) break;
        final now = _clock.now().toUtc();
        if (item.nextAttemptAt != null && now.isBefore(item.nextAttemptAt!)) {
          continue;
        }
        final claimed = await _claim(item, flushId);
        if (claimed == null) {
          // Another flush holds a live claim on this item.
          continue;
        }
        try {
          await handler(claimed);
        } on Object catch (error) {
          final isPermanent = claimed.attempts >= maxAttempts;
          if (isPermanent) {
            await _markDeadLetter(claimed, flushId, error);
            continue;
          }
          await _release(
            claimed,
            flushId,
            nextAttemptAt: _nextBackoffAt(claimed.attempts),
            lastError: '$error',
          );
          rethrow;
        }
        // Leave an uncertain remote effect pending for idempotent retry by its
        // original owner. Never continue under a replacement session.
        if (sessionChanged) {
          await _release(claimed, flushId);
          break;
        }
        await remove(claimed.id);
        count++;
      }
      return count;
    } finally {
      await subscription?.cancel();
    }
  }

  /// Claims [item] for [flushId], or returns null when another flush holds a
  /// live claim. A stale claim (older than [claimLease]) is taken over.
  Future<SyncQueueItem?> _claim(SyncQueueItem item, String flushId) async {
    final record = await database.get(collection, item.id);
    if (record == null) {
      return null;
    }
    final now = _clock.now().toUtc();
    final existingClaim = record['claimId'];
    final claimedAt = DateTime.tryParse('${record['claimedAt']}');
    final liveForeignClaim =
        existingClaim is String &&
        existingClaim.isNotEmpty &&
        existingClaim != flushId &&
        claimedAt != null &&
        now.difference(claimedAt) < claimLease;
    if (liveForeignClaim) {
      return null;
    }
    final attempts =
        (record['attempts'] is int ? record['attempts'] as int : 0) + 1;
    final claimed = <String, Object?>{
      ...record,
      'claimId': flushId,
      'claimedAt': now.toIso8601String(),
      'attempts': attempts,
    };
    await database.put(collection, item.id, claimed);
    return _itemFrom(claimed, item.id, claimId: flushId, claimedAt: now);
  }

  DateTime? _nextBackoffAt(int attempts) {
    if (initialBackoff <= Duration.zero) {
      return null;
    }
    final shift = (attempts - 1).clamp(0, 10);
    final delayMs = initialBackoff.inMilliseconds * (1 << shift);
    final cappedMs = delayMs > maxBackoff.inMilliseconds
        ? maxBackoff.inMilliseconds
        : delayMs;
    return _clock.now().toUtc().add(Duration(milliseconds: cappedMs));
  }

  /// Clears our claim so the item can be retried after [nextAttemptAt].
  Future<void> _release(
    SyncQueueItem item,
    String flushId, {
    DateTime? nextAttemptAt,
    String? lastError,
  }) async {
    final record = await database.get(collection, item.id);
    if (record == null || record['claimId'] != flushId) {
      return;
    }
    final released = Map<String, Object?>.of(record)
      ..remove('claimId')
      ..remove('claimedAt');
    if (nextAttemptAt != null) {
      released['nextAttemptAt'] = nextAttemptAt.toIso8601String();
    } else {
      released.remove('nextAttemptAt');
    }
    if (lastError != null) {
      released['lastError'] = lastError;
    }
    await database.put(collection, item.id, released);
  }

  Future<void> _markDeadLetter(
    SyncQueueItem item,
    String flushId,
    Object error,
  ) async {
    final record = await database.get(collection, item.id);
    if (record == null || record['claimId'] != flushId) {
      return;
    }
    final dead = Map<String, Object?>.of(record)
      ..remove('claimId')
      ..remove('claimedAt')
      ..remove('nextAttemptAt')
      ..['status'] = 'dead_letter'
      ..['lastError'] = '$error';
    await database.put(collection, item.id, dead);
  }

  SyncQueueItem _itemFrom(
    Map<String, Object?> record,
    String id, {
    String? claimId,
    DateTime? claimedAt,
  }) {
    return SyncQueueItem(
      id: id,
      collection: '${record['collection']}',
      key: '${record['key']}',
      operation: '${record['operation']}',
      data: Map<String, Object?>.from(
        record['data'] as Map? ?? const <String, Object?>{},
      ),
      createdAt:
          DateTime.tryParse('${record['createdAt']}') ?? _clock.now().toUtc(),
      owner: record['owner'] is String ? record['owner'] as String : null,
      claimId:
          claimId ??
          (record['claimId'] is String ? record['claimId'] as String : null),
      claimedAt: claimedAt ?? DateTime.tryParse('${record['claimedAt']}'),
      attempts: record['attempts'] is int ? record['attempts'] as int : 0,
      status: record['status'] is String ? record['status'] as String : 'pending',
      nextAttemptAt: DateTime.tryParse('${record['nextAttemptAt']}'),
      lastError: record['lastError'] is String
          ? record['lastError'] as String
          : null,
    );
  }
}
