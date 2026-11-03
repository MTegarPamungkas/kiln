# 0001 — Kiln never edits user-owned code

## Decision

Kiln only owns the files recorded in the lockfile: extension render output and
`lib/extensions/extensions.g.dart`. `kiln remove` deletes a file only while its
hash still matches the lockfile. Files edited by the user are skipped unless
`--force` is given.

## Rationale

Users must be able to fix and grow generated code without fearing it will be
overwritten. Hash-based ownership makes that boundary explicit.

## Consequences

- No update silently overwrites a user's edits.
- Conflicts are reported and the user either passes `--force` or resolves them
  manually.
- `kiln doctor` is the primary tool for detecting changes.
