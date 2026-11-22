# Cross-handle and cross-process durability

Date: 2026-11-20 (Asia/Jakarta). Addresses the remaining scope of K17 and K18 in
[findings](findings.md).

## The hazard

The local database and `Storage` used to assume a single writer. Two isolates, a
background engine, a second window or a desktop instance could:

- run the same storage migration twice, or keep a step that a killed process
  applied halfway,
- flush the same sync queue concurrently and deliver an item twice,
- import a backup while another handle writes.

`SyncQueue.flush` was serialized only per database object in one isolate, and
`StorageMigrator`'s snapshots lived in memory, so a process death inside a step
left the half-applied state behind.

## The exclusion primitive

New optional core contract `MutationLock` with `Future<T> runExclusive(action)`,
plus `SerialMutationLock` (FIFO, in-isolate, releases on error). The contract
says nothing about the mechanism; implementations decide the reach:

- `SerialMutationLock` - one isolate.
- `FileMutationLock` (`local_db`) - advisory OS lock on a file next to the
  database, so a second isolate/engine/process waits; the OS releases it when the
  process exits, so a crash cannot leave the data blocked. POSIX `fcntl` locks
  are owned by the process, so two handles in one process are not excluded;
  keep the in-isolate serialization too.
- `localDatabaseMutationLock(config)` resolves `<database path>.lock` on IO and
  returns null on the web, where one engine per origin is the guarantee.

## K17 - migration and import

`StorageMigrator` now writes a per-step recovery checkpoint
(`__kiln_migration_checkpoint`, JSON: `from`, `to`, `snapshot`) before running the
step, and clears it after the step's version write:

- A process death inside the step leaves the checkpoint; the next run restores
  the snapshot, writes the version back to `from` and runs the step again, so a
  half-applied step is never kept. Completed earlier steps are not replayed.
- A checkpoint whose `to` version was already reached only means the delete did
  not happen; recovery discards it without restoring, so a stale checkpoint
  cannot roll back a committed step.
- An unreadable checkpoint throws a typed `storageWriteFailed` failure instead of
  guessing.

`StorageMigrator` and `BackupExport.import` accept a `MutationLock`, so a second
isolate cannot migrate or import concurrently.

`BackupExport.import` is also journaled: the previous value of every record is
written to a journal collection before the record is overwritten, and a status
record stays active until the import commits. A process death inside the import
leaves that journal behind, and `BackupExport.recover` (called by the module's
`ready` when `LocalDbConfig.recoverIncompleteImports` is true, and at the start of
the next import) restores the previous values in reverse order. A committed import
marks the status inactive first, so a crash after the last write cannot roll back
data that already committed. A backup that targets the journal collection is
rejected, and an unreadable journal entry fails with `storageWriteFailed` instead
of guessing.

## K18 - sync queue

`SyncQueue` accepts a `MutationLock`; `flush` holds it for the whole flush, so two
handles over the same database cannot both read the same pending items. The
at-least-once contract is unchanged: an item is removed only after the handler
succeeds, so a crash replays it and the handler's idempotency key (`item.id`)
must absorb the repeat. Within one isolate the per-database queue still orders
flushes; the lock is what adds cross-handle exclusion.

Each item is additionally claimed durably before it is delivered. The claim stores
the flush id, a timestamp and an attempt counter: a second handle skips an item
whose claim is still live, a claim older than `claimLease` (two minutes by
default) is taken over, and a handler failure releases the claim immediately so a
retry does not wait for the lease. `pending()` exposes `claimId`, `claimedAt` and
`attempts`, so in-flight and stuck work is observable. The lock remains the
exclusion; the claim is the state that survives a crash.

## Tests

- `kiln_core`: `SerialMutationLock` serializes in arrival order and releases after
  an error.
- `storage`: an interrupted step is restored and retried once; a committed step's
  leftover checkpoint is discarded without touching later keys; an unreadable
  checkpoint fails; the supplied lock is held.
- `local_db`: `FileMutationLock` runs, releases after an error, and leaves a lock
  file; two `SyncQueue`s over separate database handles sharing one lock deliver
  four items exactly once with a maximum concurrency of one; an import journal left
  by a crash is rolled back (and recovery is idempotent), a committed journal is
  only cleared, a new import recovers before writing, journal-targeting backups are
  rejected, a live foreign claim is skipped, an expired claim is taken over with an
  incremented attempt, and a failed handler releases its claim.

The tests prove the contract and the queue/migration behaviour. They do not prove
that a second real process blocks: that is the operating system's advisory lock,
and it cannot be observed reliably inside one test process on POSIX.

## Verification

`storage` and `local_db` each passed rendered analysis and their full rendered
test suites; `kiln_core` passed 182 tests including the new lock test. All golden
snapshots, manifest/module metadata, documentation links and version checks pass,
and the bundle, registry and catalog were regenerated.

## Remaining

- The lock is advisory: a writer that does not take it is not excluded, and the
  lock file itself is not cleaned up (it is empty and harmless).
- Web relies on one engine per origin; cross-tab exclusion is not provided.
- A real two-process/isolate blocking test remains a manual device/desktop check.
- Recovery restores every record the journal lists; it cannot detect writes made by
  an unrelated writer while the import was interrupted.
