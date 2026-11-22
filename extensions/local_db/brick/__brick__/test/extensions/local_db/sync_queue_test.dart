import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/local_db/sync_queue.dart';

import 'test_support.dart';

void main() {
  test('stores and flushes pending changes', () async {
    final database = await openTestDatabase();
    final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
    final queue = SyncQueue(database: database, clock: clock);

    final first = await queue.enqueue('tasks', '1', {'title': 'one'});
    clock.advance(const Duration(seconds: 1));
    final second = await queue.enqueue('tasks', '2', {
      'title': 'two',
    }, operation: 'delete');

    final pending = await queue.pending();
    expect(pending.map((item) => item.id), [first, second]);
    expect(pending.last.operation, 'delete');

    final flushed = <String>[];
    final count = await queue.flush((item) async {
      flushed.add(item.key);
    });

    expect(count, 2);
    expect(flushed, ['1', '2']);
    expect(await queue.pending(), isEmpty);
    await database.close();
  });

  test('serializes concurrent flushes so an item is delivered once', () async {
    final database = await openTestDatabase();
    final queue = SyncQueue(database: database);
    final otherQueue = SyncQueue(database: database);
    await queue.enqueue('tasks', '1', {'title': 'one'});
    await queue.enqueue('tasks', '2', {'title': 'two'});

    final gate = Completer<void>();
    var handled = 0;
    final first = queue.flush((item) async {
      handled++;
      if (handled == 1) {
        await gate.future;
      }
    });
    final second = otherQueue.flush((item) async {
      handled++;
    });
    await Future<void>.delayed(Duration.zero);

    expect(handled, 1);

    gate.complete();
    expect(await first, 2);
    expect(await second, 0);
    expect(handled, 2);
    expect(await queue.pending(), isEmpty);
    await database.close();
  });

  test(
    'separate queue instances cannot overwrite IDs at the same instant',
    () async {
      final database = await openTestDatabase();
      final clock = FixedClock(DateTime.utc(2026));
      final first = SyncQueue(database: database, clock: clock);
      final second = SyncQueue(database: database, clock: clock);
      final ids = await Future.wait([
        first.enqueue('tasks', 'a', {}),
        second.enqueue('tasks', 'b', {}),
      ]);
      expect(ids.toSet(), hasLength(2));
      expect(await first.pending(), hasLength(2));
      await database.close();
    },
  );

  test(
    'a handler failure leaves the item pending for an at-least-once retry',
    () async {
      final database = await openTestDatabase();
      final queue = SyncQueue(database: database);
      await queue.enqueue('tasks', '1', {'title': 'one'});
      await queue.enqueue('tasks', '2', {'title': 'two'});

      var fail = true;
      await expectLater(
        queue.flush((item) async {
          if (item.key == '1' && fail) {
            throw StateError('network');
          }
        }),
        throwsStateError,
      );

      expect((await queue.pending()).map((item) => item.key), ['1', '2']);

      fail = false;
      expect(await queue.flush((item) async {}), 2);
      expect(await queue.pending(), isEmpty);
      await database.close();
    },
  );

  test('owner scoping keeps another user\'s queue out of a flush', () async {
    final database = await openTestDatabase();
    final queue = SyncQueue(database: database);
    await queue.enqueue('tasks', 'a', {'title': 'A'}, owner: 'user-a');
    await queue.enqueue('tasks', 'b', {'title': 'B'}, owner: 'user-b');

    expect((await queue.pending(owner: 'user-a')).map((item) => item.key), [
      'a',
    ]);
    final flushed = <String>[];
    final count = await queue.flush((item) async {
      flushed.add(item.key);
    }, owner: 'user-b');

    expect(count, 1);
    expect(flushed, ['b']);
    expect((await queue.pending(owner: 'user-a')).map((item) => item.key), [
      'a',
    ]);
    expect(await queue.pending(), isEmpty);
    await database.close();
  });

  test(
    'a session change stops delivery and retains the uncertain item',
    () async {
      final database = await openTestDatabase();
      final queue = SyncQueue(database: database);
      final session = SessionController(
        initialSession: const AuthSession(userId: 'a'),
      );
      await queue.enqueue('tasks', '1', {}, owner: 'a');
      await queue.enqueue('tasks', '2', {}, owner: 'a');
      await queue.enqueue('tasks', '3', {}, owner: 'b');
      final handled = <String>[];
      expect(
        await queue.flush((item) async {
          handled.add(item.key);
          session.setSession(const AuthSession(userId: 'b'));
          session.setSession(const AuthSession(userId: 'a'));
        }, session: session),
        0,
      );
      expect(handled, ['1']);
      expect(await queue.pending(owner: 'a'), hasLength(2));
      session.markUnauthenticated();
      expect(
        await queue.flush((_) async {
          fail('must not send while signed out');
        }, session: session),
        0,
      );
      expect(await queue.pending(allOwners: true), hasLength(3));
      await session.dispose();
      await database.close();
    },
  );

  test(
    'a shared mutation lock serializes flushes from separate handles',
    () async {
      final backend = _SharedBackend();
      final lock = _RecordingLock(hold: const Duration(milliseconds: 5));
      final first = SyncQueue(database: _SharedDatabase(backend), lock: lock);
      final second = SyncQueue(database: _SharedDatabase(backend), lock: lock);
      for (var index = 0; index < 4; index++) {
        await first.enqueue('tasks', '$index', <String, Object?>{
          'title': 'task $index',
        });
      }

      final delivered = <String>[];
      Future<void> handler(SyncQueueItem item) async {
        await Future<void>.delayed(const Duration(milliseconds: 2));
        delivered.add(item.id);
      }

      final counts = await Future.wait([
        first.flush(handler),
        second.flush(handler),
      ]);

      // No item is delivered twice even though two handles share the backend.
      expect(delivered, hasLength(4));
      expect(delivered.toSet(), hasLength(4));
      expect(counts.fold<int>(0, (sum, count) => sum + count), 4);
      expect(lock.maxActive, 1);
    },
  );

  test('skips an item another flush has claimed', () async {
    final database = await openTestDatabase();
    final clock = FixedClock(DateTime.utc(2026, 11, 21));
    final queue = SyncQueue(database: database, clock: clock);
    final id = await queue.enqueue('tasks', '1', <String, Object?>{
      'title': 'one',
    });
    final record = await database.get(queue.collection, id);
    await database.put(queue.collection, id, <String, Object?>{
      ...record!,
      'claimId': 'other-flush',
      'claimedAt': clock.now().toUtc().toIso8601String(),
      'attempts': 1,
    });

    final handled = <String>[];
    expect(await queue.flush((item) async => handled.add(item.key)), 0);

    expect(handled, isEmpty);
    expect((await queue.pending()).single.claimId, 'other-flush');
    await database.close();
  });

  test('takes over a claim left behind by a crash after the lease', () async {
    final database = await openTestDatabase();
    final clock = FixedClock(DateTime.utc(2026, 11, 21));
    final queue = SyncQueue(
      database: database,
      clock: clock,
      claimLease: const Duration(minutes: 2),
    );
    final id = await queue.enqueue('tasks', '1', <String, Object?>{
      'title': 'one',
    });
    final record = await database.get(queue.collection, id);
    await database.put(queue.collection, id, <String, Object?>{
      ...record!,
      'claimId': 'crashed-flush',
      'claimedAt': clock.now().toUtc().toIso8601String(),
      'attempts': 1,
    });
    clock.advance(const Duration(minutes: 3));

    final attempts = <int>[];
    expect(await queue.flush((item) async => attempts.add(item.attempts)), 1);

    expect(attempts, [2]);
    expect(await queue.pending(), isEmpty);
    await database.close();
  });

  test('releases the claim when the handler fails', () async {
    final database = await openTestDatabase();
    final clock = FixedClock(DateTime.utc(2026, 11, 21));
    final queue = SyncQueue(database: database, clock: clock);
    await queue.enqueue('tasks', '1', <String, Object?>{'title': 'one'});

    await expectLater(
      queue.flush((item) async => throw StateError('offline')),
      throwsStateError,
    );

    final pending = await queue.pending();
    expect(pending.single.claimId, isNull);
    expect(pending.single.attempts, 1);

    expect(await queue.flush((item) async {}), 1);
    expect(await queue.pending(), isEmpty);
    await database.close();
  });
}

final class _SharedBackend {
  final Map<String, Map<String, Map<String, Object?>>> data =
      <String, Map<String, Map<String, Object?>>>{};
}

/// LocalDatabase handle over shared state, so two queues model two isolates.
final class _SharedDatabase implements LocalDatabase {
  _SharedDatabase(this.backend);

  final _SharedBackend backend;

  Map<String, Map<String, Object?>> _collection(String collection) => backend
      .data
      .putIfAbsent(collection, () => <String, Map<String, Object?>>{});

  @override
  Future<void> put(
    String collection,
    String key,
    Map<String, Object?> data,
  ) async {
    _collection(collection)[key] = Map<String, Object?>.of(data);
  }

  @override
  Future<Map<String, Object?>?> get(String collection, String key) async {
    final record = _collection(collection)[key];
    return record == null ? null : Map<String, Object?>.of(record);
  }

  @override
  Future<List<LocalRecord>> query(
    String collection, {
    LocalQuery? query,
  }) async {
    final records =
        <LocalRecord>[
          for (final entry in _collection(collection).entries)
            LocalRecord(
              key: entry.key,
              data: Map<String, Object?>.of(entry.value),
            ),
        ]..sort(
          (left, right) => '${left.data['createdAt']}'.compareTo(
            '${right.data['createdAt']}',
          ),
        );
    return records;
  }

  @override
  Future<void> delete(String collection, String key) async {
    _collection(collection).remove(key);
  }

  @override
  Stream<List<LocalRecord>> watch(String collection, {LocalQuery? query}) =>
      const Stream<List<LocalRecord>>.empty();

  @override
  Future<void> close() async {}
}

final class _RecordingLock implements MutationLock {
  _RecordingLock({this.hold = Duration.zero});

  final Duration hold;
  final SerialMutationLock _inner = SerialMutationLock();
  int active = 0;
  int maxActive = 0;

  @override
  Future<T> runExclusive<T>(Future<T> Function() action) {
    return _inner.runExclusive(() async {
      active++;
      if (active > maxActive) {
        maxActive = active;
      }
      try {
        await Future<void>.delayed(hold);
        return await action();
      } finally {
        active--;
      }
    });
  }
}
