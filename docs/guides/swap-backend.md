# Swapping the backend

Goal: feature code does not change when the backend is swapped.

## Principles

- Features use the `AuthRepository`, `RemoteDatabase`, and `FileStorage`
  contracts from `kiln_core`.
- The full backends (`appwrite`, `firebase`, `supabase`) are exclusive
  extensions that provide those three contracts. `neon` provides
  `RemoteDatabase` only, over the Neon Data API, so it swaps the database
  without changing auth or file storage. Install one `RemoteDatabase`
  provider at a time; the resolver rejects two.
- No concrete backend types are imported in `features/`.

## Steps (phase 2)

1. Make sure features read contracts from the Registry.
2. `kiln remove supabase` (edited files will be reported).
3. `kiln add appwrite` and fill in the endpoint/project/database/bucket prompts.
4. Run `kiln doctor`, then the backend contract tests.
5. Compare `lib/extensions/`; the feature code stays the same.

`examples/backend_swap` shows both variants and the unchanged feature code.
