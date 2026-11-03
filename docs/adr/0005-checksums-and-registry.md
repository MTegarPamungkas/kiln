# 0005 — Archive checksums and the registry as the extension source

## Decision

Extension distribution uses `.tgz` archives with a SHA-256 recorded in the
registry index. Checksums are verified before installation; archives are
extracted with path traversal rejected. The registry stores the id, version,
tier, requires, and compatibility.

## Rationale

Extension content must be verifiable and selectable according to the project's
`kiln_core` compatibility.

## Consequences

- `kiln_store` becomes the trust boundary between the registry and the
  installer.
- Offline mode uses the local cache.
- The final distribution model (Git URL, separate registry, or both) is still
  parked and recorded in the roadmap.
