# Changelog

## 0.1.0

- A real multi-process test kills a migration step after a partial write and
  verifies that a fresh process restores the on-disk checkpoint and completes the
  step.

- Each migration step records a recovery checkpoint before it runs, so a process
  death inside the step is rolled back and retried on the next start instead of
  keeping a half-applied state. A checkpoint whose target version was already
  reached is discarded without restoring, and an unreadable checkpoint fails
  clearly. `StorageMigrator` also accepts a `MutationLock`.

- Migration compensation includes failed version writes; runs sharing a storage
  object serialize and failed restoration is reported explicitly.

- Initial release.
- `StorageMigrator` checkpoints the version after every step, restores the
  storage when a migration throws, and rejects a missing migration instead of
  silently advancing the version.
