# Changelog

## 0.1.1

- Retry transient Windows sharing errors when publishing a staged project and preserve the original error if cleanup fails.
- Preflight scaffolding and publish the project after Flutter dependency
  resolution. Fresh projects use the CLI release commit when resolving Kiln from Git.
- Resolve registry and bundled extensions together and use locked archives for
  installed registry extensions during maintenance.
- Check CLI, Dart, Flutter, and project platform compatibility during planning.

- Add and store install report unsuccessful verification as rolled back.
  Remove can verify with `--verify` and reports cancellation in English.

- Setup documents and preserves env:NAME client-value references; bundled
  analytics, crash reporting and Supabase render build-variable expressions.

- Remove the Neon extension from the bundled catalog and setup rules.
- Guard all project mutation commands with an OS-backed project lock; read-only
  inspection and dry runs remain available while another operation is active.

- `kiln setup [extension...]` reviews any bundled installed extension;
  `--all` configures a batch in one verified transaction. Without names,
  setup lists configuration status without changing files.
- Setup handles all manifest prompt types, saved values, secret masking, and
  explicit overrides. Unchanged settings leave customized source alone.
- `kiln doctor` checks local configuration for every bundled installed
  extension and suggests setup commands. Runtime and external setup remain
  explicitly unverified.
- `kiln upgrade` resolves prompts before touching the project and rolls back
  managed files when verification fails.
- `kiln upgrade` now applies bundled-catalog upgrades when no registry is
  configured, instead of only listing the candidates.
- Registry caches are scoped to the registry identity and verify the selected
  checksum before extraction.

## 0.1.0

- Initial release.
