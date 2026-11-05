# 0002 — Extensions depend on capabilities, not ids

## Decision

The manifest uses `provides` and `requires` containing capability names.
Extensions do not import other extensions and do not write other extensions'
ids.

## Rationale

Ids bind implementations. Capabilities let a backend or transport be swapped
without changing dependent extensions.

## Consequences

- The resolver picks providers and detects conflicts.
- Two providers for the same capability are rejected.
- Slots provide attachment points for behavior that cannot be expressed as a
  capability.
