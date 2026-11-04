# Changelog

All notable changes to the Kiln SDK are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Individual packages and extensions keep their own `CHANGELOG.md`; this file
records release-level changes for the monorepo.

## [0.2.0] - 2026-11-04

First tagged release of the audit pass that took every extension to a
production-ready, English-language, fully Gate-connected state.

### Highlights

- **All 29 extensions audited**: user-facing strings (failure messages, manifest
  labels, prompts, manual steps, hooks, docs, and test fixtures) normalized to
  English across the whole SDK. The Supabase, Firebase, REST-auth, and Biometric
  backends no longer surface Indonesian text.
- **One-call Result facade** (`Gate`) completed for every capability, with typed
  verbs added where the Result surface was thin, so apps get `Result`/`Failure`
  instead of raw exceptions and never need `registry.read` for common flows.
- **Self-hosted / local backends** are now first-class: Supabase and Appwrite
  report an `insecure_http` support detail so `kiln doctor` warns on cleartext
  `http://` endpoints that need an Android network security config.
- Two real correctness fixes: Riverpod provider identity stability and expanded
  Gate coverage.

### Added

- `Gate` Result verbs across the foundation extensions — storage/secure-storage
  key management, logger level/records, HTTP verbs (get/post/put/patch/delete +
  send), http_cache, http_retry events, connectivity reachability, deep-link and
  universal-link builders, permission batch + settings verbs, location-service
  toggle, and notification `cancelAll`.
- `gate_social_login.dart` — `socialLogin`, `socialSignIn`, `socialSignOut`.
- `gate.supportedLocales` (l10n) so an app-owned language picker can list locales
  through the Gate instead of reading `L10nConfig` from the registry.
- `AppwriteConfig.isInsecureTransport` and the `insecure_http` support detail.

### Fixed

- **riverpod**: `kilnProvider<T>()` now caches providers by type. Riverpod keys
  providers by object identity, so the previous fresh-per-call factory made the
  documented inline `ref.watch(kilnProvider<Contract>())` pattern create a new
  provider node on every call.

### Changed

- **firebase, rest_auth, social_login, biometric**: all SDK messages, manifest
  prompts/manual steps, and hooks localized to English; Firebase error-code
  switch labels left intact.
- **supabase**: English messages plus local/self-hosted `http` guidance.
- **go_router**: test fixtures made language-neutral.
- **kiln_cli** (0.1.5): CLI chrome (labels, prompts, errors, success messages)
  fully English; version constant and pubspec bumped.

### Package versions

- `kiln_core` 0.1.3, `kiln_cli` 0.1.5.
- Extensions bumped where behavior changed, e.g. firebase 0.3.0, biometric 0.3.0,
  riverpod 0.3.0, social_login 0.3.0, l10n 0.3.0, appwrite 0.2.0, go_router 0.3.1,
  rest_auth 0.1.3.

### Verified

Every phase regenerated goldens, bundles, and the registry (`--check` green),
then ran `dart analyze`, the `kiln_core` suite (146 tests), the per-extension
suites (`flutter analyze` of the rendered app), `check_docs` (65 files), and
`lint_extensions` (29 extensions OK), and rebuilt `bin/kiln.exe`. Supabase auth,
CRUD, storage, and image-picker were additionally proven end-to-end on a physical
Android device against a local Dockerized Supabase.
