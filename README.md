# Kiln

Kiln generates and evolves Flutter applications through composable
extensions. A generated application depends only on the contracts in
`kiln_core`; extensions provide those contracts and communicate through
slots, never by importing each other.

## Status

Fase fondasi sudah berjalan end-to-end:

- `kiln create` menghasilkan aplikasi dari brick `app_basic`.
- `kiln add dio` memasang extension secara transaksional, termasuk patch
  Android, dependency pubspec, lockfile, dan `extensions.g.dart`.
- `kiln remove`, `doctor`, `list`, `graph`, `rollback`, `config`, `cache`,
  `store`, `completion`, dan `ext new/validate/test/pack` tersedia.
- Proyek hasil generate lolos `flutter analyze` dan `flutter test`.
- Dua puluh enam extension bawaan: `analytics`, `appwrite`, `biometric`,
  `bloc`, `connectivity`, `deep_link`, `dio`, `env`, `firebase`, `flavors`,
  `go_router`, `http_cache`, `http_retry`, `image_picker`, `l10n`, `local_db`,
  `logger`, `notifications`, `permission`, `rest_auth`, `riverpod`,
  `secure_storage`, `social_login`, `storage`, `supabase`, dan `theme`.
- `kiln create --state bloc` dan `--state riverpod` menghasilkan aplikasi yang
  sudah terpasang state management, session bridge, dan contoh counter.
- `dio + http_retry + http_cache` merakit pipeline HTTP dengan urutan priority:
  request id/user agent, retry, lalu cache.
- Storage group: `storage` (SharedPreferences, typed key, TTL, migrasi),
  `secure_storage` (gateway, token store, first-run wipe, health check), dan
  `local_db` (Sembast, query, watch, transaksi, backup, sync queue, migrasi,
  enkripsi AES-GCM opsional).
- Platform group: `connectivity` (NetworkMonitor, probe, offline guard),
  `permission` (kind bertipe, flow rationale, widget gate), `notifications`
  (channel, payload bertipe, tap hub, reminder scheduler), dan `image_picker`
  (MIME sniffer, validasi, lost data recovery, adapter unggah).
- Auth/backend group: `rest_auth` (token store, refresh single-flight, 401
  handler), `appwrite`, `firebase`, dan `supabase` (auth, remote database,
  file storage, akun), plus `social_login` dan `biometric` (app lock dan
  penyimpanan terlindungi).
- Navigasi/UI group: `go_router` (route slot, guard, deep link dan tap
  notifikasi), `deep_link` (allowlist, normalisasi, dedup, builder), `theme`
  (warna, token desain, mode terang/gelap) dan `l10n` (ARB + gen-l10n,
  locale, plural, format, pesan Failure).
- Tooling group: `env` (nilai build-time bertipe), `flavors` (entry point dan
  banner), `logger` (sink, redaksi, breadcrumb, HTTP log), dan `analytics`
  (PostHog, consent gate, PII scrubbing).
- Registry: `kiln_store` (client, cache, checksum, trust, pack/publish),
  `registry/` berisi index dan arsip, serta `kiln store install`,
  `kiln upgrade`, dan `kiln ext publish`.
- `kiln_lints`: lima custom lint (`no_cross_extension_import`,
  `prefer_contract_over_impl`, `no_plugin_in_features`,
  `no_edit_generated_files`, `require_failure_handling`) pada analyzer 8.
- Phase 4: contoh `examples/minimal`, `full_stack`, `backend_swap`, dan
  `custom_extension`; golden render per extension; workflow drift, docs, dan
  release.
- Setiap extension disertai test manifest, render, analyze, serta test brick
  yang berjalan di aplikasi hasil generate.

Lihat [getting-started.md](docs/getting-started.md) dan
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

Pemeriksaan kualitas yang dipakai CI:

```bash
dart run tool/verify_extensions.dart --check   # golden render per extension
dart run tool/check_docs.dart --check          # tautan dan code fence docs
dart run tool/check_drift.dart --check         # constraint vs versi pub.dev
dart run tool/registry.dart --check            # index dan arsip registry
dart run tool/bundle.dart --check
dart run tool/gen_catalog_docs.dart --check
```

`dart run tool/verify_extensions.dart --analyze [--only <id>]` merender
app_basic plus satu extension ke fixture bersama dan menjalankan
`flutter pub get` + `flutter analyze`.

Workflow GitHub: `ci`, `extensions`, `bundles_check`, `smoke` (nightly),
`drift` (nightly), `docs`, dan `release` (tag `v*`).

Membuat aplikasi dari source:

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
