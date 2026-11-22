# Offline-first pattern

The default read path is local; the network is a background synchronizer. This
keeps the UI instant and usable with no connection.

1. **Read local first.** Serve the screen from `LocalDatabase` immediately.
2. **Show connectivity.** Reflect `NetworkMonitor` status so the user knows
   whether changes can sync.
3. **Queue writes.** On a mutation, write locally and enqueue the change in the
   `SyncQueue`; do not wait for the network.
4. **Flush when online.** When the network is back, send queued items to
   `RemoteDatabase` and apply the server result back into the local store.
5. **Observe, don't poll.** Use `LocalDatabase.watch` so the UI updates when the
   sync result lands.

Decide a conflict rule up front — last-write-wins, server-version-wins, or manual
merge — and apply it in the flush step so a failed sync never silently drops data.

`SyncQueue.flush` is serialized: concurrent callers cannot deliver the same item
twice, and an item is removed only after its handler succeeds. Delivery is
at-least-once across process restarts, so use `SyncQueueItem.id` as a stable
idempotency key for the remote effect. Enqueue an `owner` (for example the
signed-in user) and flush with the same owner so a user switch does not replay
another user's queue.

Serialization in one isolate is not enough when a background isolate, a second
window or a desktop instance can flush the same database. Pass the file lock from
the extension so only one of them delivers at a time:

```dart
final config = registry.read<LocalDbConfig>();
final queue = SyncQueue(
  database: registry.read<LocalDatabase>(),
  lock: await localDatabaseMutationLock(config),
);
```

`FileMutationLock` takes a blocking advisory OS lock, released when the process
exits, so a second process waits instead of failing and a crash cannot leave the
queue blocked. POSIX locks are per process, so two isolates in one process still
rely on the queue's in-isolate serialization; on Windows, do not nest the same
lock path in one process. On the web `localDatabaseMutationLock` returns null: one
engine per origin is the guarantee there, not cross-tab exclusion.
`BackupExport.import` accepts the same lock.
