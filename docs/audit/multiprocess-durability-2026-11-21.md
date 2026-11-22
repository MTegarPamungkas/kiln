# Multi-process lock, recovery and lease checks

Date: 2026-11-21 (Asia/Jakarta). No commit or deployment was made. This is the
K17/K18 follow-up to [cross-handle durability](cross-handle-durability-2026-11-20.md).

## Why a second process

The earlier K17/K18 work proved the contracts with fake locks, in-memory
backends, and simulated crashes. That could not prove three things the design
claims:

- a competing writer **waits** instead of mutating at the same time,
- a process **killed** inside a migration, import, or claim leaves state the next
  process can recover, and
- the operating system, not a Dart `finally`, releases the lock when that
  process dies.

POSIX `fcntl` locks are owned by the process, and a caught exception is not a
process death. Both properties need a real second process. Each test starts a
worker with the rendered fixture's package config, coordinates with marker files,
and either hard-kills it or lets it exit in the middle of the mutation.

## Defect found and fixed: the lock did not block

`FileMutationLock` used `FileLock.exclusive`. That is a **non-blocking** attempt:
on Windows it is `LockFileEx(... LOCKFILE_FAIL_IMMEDIATELY)`, on POSIX it is
`fcntl(F_SETLK)`. The first contention threw

```
PathAccessException: lock failed ... another process has locked a portion of the
file, errno = 33
```

instead of waiting. A second process therefore did not serialise after the first:
`SyncQueue.flush`/`StorageMigrator.run` with the shared lock would fail rather
than queue behind the holder. The extension docs and the K18 report promised a
wait; the tests found the opposite.

The fix is `FileLock.blockingExclusive`: Windows `LockFileEx` without
`FAIL_IMMEDIATELY`, POSIX `F_SETLKW`. The contract is now true for separate
processes. The unit test cannot catch this:

- on Windows two handles in one process would wait on themselves (deadlock), and
- on POSIX two handles in one process do not conflict at all.

Only the multi-process suite can exercise it.

## Tests

`local_db` (`test/extensions/local_db/multiprocess_test.dart`):

| Test | Process shape | What it proves |
| --- | --- | --- |
| lock holder blocks the test process | worker holds, test process competes | the test process enters only after the worker releases (400 ms observed, entry after release) |
| kill while holding | worker hard-killed while locked | the next writer acquires in milliseconds; the OS released the lock |
| three-process flush race | 24 queued items, 3 processes released together by a go file, 5 ms handlers | exactly 24 unique deliveries, no overlapping handler intervals across processes, reported counts sum to 24, queue empty |
| claim lease after crash | worker claims one item, then is hard-killed | the two unclaimed items are delivered, the live claim is kept (`claimId`, `claimedAt`, `attempts=1`); after the 300 ms lease a new queue takes it over once with `attempts=2` |
| import crash | worker exits 70 inside `BackupExport.import` after the first data write | journal stays active, the partial record is on disk; a fresh handle rolls it back, keeps untouched records, and a new import applies both records |

`storage` (`test/extensions/storage/multiprocess_test.dart`):

| Test | Process shape | What it proves |
| --- | --- | --- |
| migration crash | worker killed inside a step after writing a half key | the checkpoint holds `from`/`to`/the pre-step snapshot; a fresh process restores the snapshot, removes the half key, and completes the step at version 1 |

The flush race uses a shared durable JSON store, not Sembast: Sembast documents
single-process access, and the test is about the lock and the claim, not about
two Sembast handles. The crash tests open Sembast only after the worker is dead,
so they prove durable state and recovery without relying on concurrent Sembast
access.

## Evidence

- `dart run tool/verify_extensions.dart --only local_db --analyze --test`:
  rendered analysis clean, full suite passed, including the five multi-process
  tests.
- `dart run tool/verify_extensions.dart --only storage --analyze --test`:
  rendered analysis clean, full suite passed, including the one multi-process
  test.
- `dart analyze`, `packages/kiln_core` (182 tests), `packages/kiln_cli`
  (160 tests), `tool/check_metadata.dart`, `tool/check_versions.dart`,
  `tool/check_docs.dart`, `tool/bundle.dart --check` and
  `tool/registry.dart --check` stayed green.

Reproduction (no device, network, or credentials needed):

```sh
dart run tool/verify_extensions.dart --only local_db --analyze --test
dart run tool/verify_extensions.dart --only storage --analyze --test
```

The workers locate Dart through `KILN_DART`, then `FLUTTER_ROOT`, then the
running executable's cache, then `dart` on `PATH`. The suite was run on Windows 11
with Dart 3.13.7.

## Remaining limits

- POSIX locks are owned by the process: two isolates in one process are still not
  excluded. Keep the in-isolate queue serialization.
- Windows locks belong to the file handle: nesting `runExclusive` on the same
  path in one process waits for itself. Do not nest the same lock.
- The lock is advisory. A writer that does not take it is not excluded, and the
  lock file is left behind (empty and harmless).
- Web has one engine per origin; its `FileMutationLock` is a per-path serial
  lock, not cross-tab exclusion.
- Without the lock, a live claim can expire while a slow handler is still
  running. The lease is the crash-recovery path, not a lock replacement.
- Storage recovery restores the whole snapshot and still cannot distinguish keys
  written by an unrelated writer during the interrupted window.
- Import recovery restores exactly what the journal lists; it does not detect an
  unrelated writer.
