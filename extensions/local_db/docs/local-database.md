# Local database

Persist structured collections with the Sembast-backed `LocalDatabase` — an
offline-first store that the `connectivity` and `rest_auth` flows build on:

```dart
final database = RegistryScope.read<LocalDatabase>(context);
await database.put('tasks', '1', {'title': 'Write docs'});
final tasks = await database.query(
  'tasks',
  query: const LocalQuery(orderBy: 'title'),
);
```

`TypedCollection<T>` turns documents into models. `watch` emits a snapshot of the
collection every time the data changes.

The database opens lazily on first use. A failed open is not cached, so the next
operation retries; `close()` (also called by the module on shutdown) releases the
native database handle.

## Backup import and recovery

`BackupExport.import` validates the whole document before writing and compensates
in memory when a write fails. It also journals the previous value of every record
before overwriting it, with a status record that stays active until the import
commits. If the process dies inside the import, the module's `ready` calls
`BackupExport.recover` and restores the previous values, so the application never
reads a half-imported database. A committed import flips the status first, so its
data is never rolled back by a crash during cleanup.

Recovery is automatic while `LocalDbConfig.recoverIncompleteImports` is true
(the default). Set it to false if `local_db` must stay lazy at startup, and call
`recover` yourself before the first read:

```dart
await const BackupExport().recover(database: database);
```

Pass a `MutationLock` when another isolate or process can import at the same
time; the journal keeps one writer consistent after a crash, it does not exclude
a second writer.

## Claims and cross-process flushes

Each `SyncQueue` item is claimed durably before delivery: the record carries the
flush id, a timestamp and an attempt counter. A second handle skips an item whose
claim is still live, a claim older than `claimLease` (two minutes by default) is
taken over after a crash, and a handler failure releases the claim so the retry
does not wait for the lease. Pass the file lock from the extension to exclude a
background isolate or a second engine outright:

```dart
final queue = SyncQueue(
  database: database,
  lock: await localDatabaseMutationLock(registry.read<LocalDbConfig>()),
);
```

`pending()` exposes `claimId`, `claimedAt` and `attempts`, so in-flight or stuck
work is visible in diagnostics.

The file lock is a blocking advisory OS lock: a competing process parks until the
holder releases it, and the operating system releases it when that process dies.
On POSIX the lock belongs to the process, so two isolates in one process are not
excluded (the queue's in-isolate serialization still applies); on Windows, do not
nest the same lock path in one process, because the second acquisition waits for
itself.
