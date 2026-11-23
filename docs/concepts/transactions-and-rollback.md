# Transactions and rollback

Every `add`/`remove` runs inside a `Transaction`:

1. Snapshot the files that will change into `.kiln/backups/<id>/`.
2. Record the operations in `.kiln/journal/<id>.json` before any file is
   written.
3. Apply all changes.
4. Commit: move the journal into the backup folder as history.
5. On failure: `rollback()` restores the snapshot and deletes new files.

`kiln rollback` cancels an interrupted transaction first, then the last
completed one. A journal still in the active directory remains discoverable
if the process stops while publishing commit history. Rollback validates
required snapshots before restoring any file and keeps recovery data if a
snapshot is missing. Kiln keeps the ten most recent completed backups.

`.kiln/journal`, `.kiln/backups`, and `.kiln/logs` are ignored by Git.
