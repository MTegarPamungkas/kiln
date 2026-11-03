# 0004 — Changes are applied through transactions with a journal

## Decision

`add` and `remove` write their changes inside a `Transaction` with snapshots in
`.kiln/backups` and a journal in `.kiln/journal`. Commit moves the journal into
the backup history; `kiln rollback` restores an interrupted or the last
transaction.

## Rationale

An installation touches many files: render output, pubspec, native patches,
codegen, and the lockfile. A failure halfway through must be reversible.

## Consequences

- New files are deleted on rollback; existing files are restored from the
  snapshot.
- `doctor` reports journals that are still open.
- Backups are cleaned up during rollback but kept after commit for the next
  rollback.
