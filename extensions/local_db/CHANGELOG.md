# Changelog

## 0.1.5

- Never dead-letter `SyncQueue` items on transient failures (network, timeout,
  auth/session, unavailable, cancelled, or retryable `Failure`); only count
  non-transient failures toward `maxAttempts`.
- Add `SyncQueue.requeueDeadLetters()` to move dead-lettered items back into
  active delivery with a fresh failure budget.

## 0.1.4

- Add `maxAttempts`, per-item exponential backoff (`nextAttemptAt`), and
  `dead_letter` status to `SyncQueue` so permanent failures no longer block
  subsequent queued items, and push `owner`/`status`/`limit` filtering into the
  local database query.
- Track closed state in `SembastLocalDatabase` so operations after `close()`
  fail cleanly with `FailureCode.databaseUnavailable` instead of silently
  reopening the database.

## 0.1.3

- Make `sync_queue_test.dart` wait deterministically for the first flush callback
  before asserting serialization under concurrent flushes.

## 0.1.2

- Update dependency constraints (`sembast` `^3.10.1`, `sembast_web` `^2.4.7`).

## 0.1.1

- Repack archive with deterministic cross-OS gzip and without root `test/`.

## 0.1.0

- `FileMutationLock` now takes a blocking operating-system lock. A competing
  process waits for the holder instead of failing with a lock error, and a killed
  process's lock is released by the OS. Real multi-process tests cover the wait,
  crash release, a three-process flush race, claim lease takeover, and import
  crash rollback.

- `BackupExport.import` journals the previous value of every record and rolls an
  interrupted import back at startup (or before the next import), with a commit
  fence so a completed import is never rolled back.
- Sync queue items carry a durable claim (flush id, timestamp, attempts) that a
  second flush skips while live, takes over after `claimLease`, and releases when
  the handler fails.

- `SyncQueue.flush` accepts a `MutationLock`, and the extension ships
  `FileMutationLock` plus `localDatabaseMutationLock(config)` so a background
  isolate or a second engine cannot deliver the same items. `BackupExport.import`
  accepts the same lock.

- Unscoped sync delivery selects only unowned items. Optional session-scoped
  flush stops on a session event and retains uncertain effects for idempotent retry.

- Backup import validates nested JSON and compensates writes that mutate before
  failing, with explicit rollback failure reporting.
- Queue IDs include a random instance namespace; flushes serialize across
  queue instances sharing one database object and collection.

- Initial release.
- The module closes its Sembast database on shutdown, and a failed lazy open
  is no longer cached so the next call can retry.
- `SyncQueue.flush` is serialized with optional owner scoping and documented
  at-least-once delivery; `BackupExport.import` validates versions/records and
  rolls back partial writes.
