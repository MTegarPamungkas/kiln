# Kiln

Kiln generates and evolves Flutter applications through composable
extensions. A generated application depends only on the contracts in
`kiln_core`; extensions provide those contracts and communicate through
slots, never by importing each other.

## Status

The foundation phase runs end-to-end:

- `kiln create` generates a minimal application root from the `app_basic`
  brick; `--template app` adds the starter page and demo shell.
- `kiln add dio` installs an extension transactionally, including Android
  patches, pubspec dependencies, lockfile, and `extensions.g.dart`.
- `kiln remove`, `doctor`, `list`, `graph`, `rollback`, `config`, `cache`,
  `store`, `completion`, and `ext new/validate/test/pack` are available.
- Generated projects pass `flutter analyze` and `flutter test`.
- Twenty-six built-in extensions: `analytics`, `appwrite`, `biometric`,
  `bloc`, `connectivity`, `deep_link`, `dio`, `env`, `firebase`, `flavors`,
  `go_router`, `http_cache`, `http_retry`, `image_picker`, `l10n`, `local_db`,
  `logger`, `notifications`, `permission`, `rest_auth`, `riverpod`,
  `secure_storage`, `social_login`, `storage`, `supabase`, and `theme`.
- `kiln create --state bloc` and `--state riverpod` generate an application
  with state management, the session bridge, and a counter example already
  wired up.
- `dio + http_retry + http_cache` assembles an HTTP pipeline in priority order:
  request id/user agent, retry, then cache.
- Storage group: `storage` (SharedPreferences, typed keys, TTL, migration),
  `secure_storage` (gateway, token store, first-run wipe, health check), and
  `local_db` (Sembast, queries, watch, transactions, backup, sync queue,
  migration, optional AES-GCM encryption).
- Platform group: `connectivity` (NetworkMonitor, probe, offline guard),
  `permission` (typed kinds, rationale flow, widget gate), `notifications`
  (channels, typed payloads, tap hub, reminder scheduler), and `image_picker`
  (MIME sniffer, validation, lost data recovery, upload adapter).
- Auth/backend group: `rest_auth` (token store, single-flight refresh, 401
  handler), `appwrite`, `firebase`, and `supabase` (auth, remote database,
  file storage, accounts), plus `social_login` and `biometric` (app lock and
  protected storage).
- Navigation/UI group: `go_router` (route slot, guards, deep links and
  notification taps), `deep_link` (allowlist, normalization, dedup, builder),
  `theme` (colors, design tokens, light/dark mode) and `l10n` (ARB + gen-l10n,
  locales, plurals, formatting, Failure messages).
- Tooling group: `env` (typed build-time values), `flavors` (entry points and
  banners), `logger` (sinks, redaction, breadcrumbs, HTTP logs), and `analytics`
  (PostHog, consent gate, PII scrubbing).
- Registry: `kiln_store` (client, cache, checksum, trust, pack/publish),
  `registry/` holds the index and archives, plus `kiln store install`,
  `kiln upgrade`, and `kiln ext publish`.
- `kiln_lints`: five custom lints (`no_cross_extension_import`,
  `prefer_contract_over_impl`, `no_plugin_in_features`,
  `no_edit_generated_files`, `require_failure_handling`) on analyzer 8.
- Phase 4: the `examples/minimal`, `full_stack`, `backend_swap`, and
  `custom_extension` examples; per-extension golden renders; drift, docs, and
  release workflows.
- Every extension ships with manifest, render, and analyze tests, plus brick
  tests that run on the generated application.

See [getting-started.md](docs/getting-started.md) and
[roadmap.md](docs/roadmap.md).

## Packages

| Package | Purpose |
| --- | --- |
| `kiln_core` | Contracts, failures, registry runtime, sessions, privacy |
| `kiln_extension_sdk` | Manifest, resolver, renderer, installer, migrations |
| `kiln_cli` | The `kiln` command line interface |
| `kiln_store` | Registry client, checksum verification, publishing |
| `kiln_testing` | Fakes, contract suites, and widget test harness |
| `kiln_lints` | Custom lint rules for contracts, plugins, and generated files |

## Repository layout

- `packages/` — Dart packages
- `extensions/` — extension manifests and Mason bricks
- `bricks/` — project templates used by `kiln create` and `kiln ext new`
- `schemas/` — JSON Schemas for every YAML file Kiln reads
- `docs/` — user and contributor documentation
- `tool/` — bundling, registry, drift, and release scripts

## Development

```bash
flutter pub get
dart analyze

cd packages/kiln_core && dart test
cd ../kiln_testing && flutter test
cd ../kiln_extension_sdk && dart test
cd ../kiln_cli && dart test
cd ../../extensions/dio && dart test
```

Quality checks used by CI:

```bash
dart run tool/verify_extensions.dart --check   # per-extension golden render
dart run tool/check_docs.dart --check          # doc links and code fences
dart run tool/check_drift.dart --check         # constraints vs pub.dev versions
dart run tool/registry.dart --check            # registry index and archives
dart run tool/bundle.dart --check
dart run tool/gen_catalog_docs.dart --check
```

`dart run tool/verify_extensions.dart --analyze [--only <id>]` renders
app_basic plus one extension into a shared fixture and runs
`flutter pub get` + `flutter analyze`.

GitHub workflows: `ci`, `extensions`, `bundles_check`, `smoke` (nightly),
`drift` (nightly), `docs`, and `release` (`v*` tags).

Creating an application from source:

```bash
dart run packages/kiln_cli/bin/kiln.dart create my_app \
  --core-path "$PWD/packages/kiln_core" \
  --with dio \
  --answer base_url=https://api.example.com \
  --yes
```

The design blueprint lives in
[docs/folder-structure.md](docs/folder-structure.md).

## Dependency policy

Every direct dependency uses a caret constraint on the newest release the
current toolchain can resolve, so a routine upgrade only needs
`flutter pub upgrade --major-versions`.

Two packages are intentionally held back because the SDK or a plugin pins
them:

- `test` stays on `1.31.1` while the Flutter SDK pins `test_api 0.7.12`;
  `test 1.33` requires `test_api 0.7.15`.
- `custom_lint_builder` 0.8.x pins `analyzer ^8`; `kiln_lints` ships on
  analyzer 8 and moves to analyzer 14 when upstream supports it.

Both constraints move forward as soon as the upstream packages allow it.
