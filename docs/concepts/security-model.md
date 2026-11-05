# Security model

## Trust tiers

- `official` — maintained by the Kiln team.
- `verified` — reviewed, checksum and manifest verified.
- `community` — hooks require explicit approval.

## Hooks

Hooks run code on the user's machine. `HookPolicy` only allows the
`official`/`verified` tiers or approval via `--yes`. In the foundation phase,
hooks are not executed automatically by the installer; extensions that have them
are reported.

## Checksums and archives

`kiln_store` (registry phase) verifies an archive's SHA-256 before installing
and rejects path traversal during extraction. The registry index carries the
version, tier, requires, and compatibility.

## Secrets

- `secret` prompts are not written to `kiln.yaml`.
- Build-time values are read through `String.fromEnvironment`.
- `--dart-define` values can still be extracted from the binary; do not store
  server keys in a client application.
- The logger, analytics, and crash reporter use `PiiRedactor` and
  `ConsentController` from `kiln_core`.

## Rollback

A transaction stores a snapshot before changing files plus a journal for
rollback, so a mid-process failure never leaves the project half-written.
