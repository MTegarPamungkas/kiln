# Repository layout

Current working tree, 2026-11-21. This is a directory map, not a file inventory:
the earlier version listed every file and went stale within days. Add a line here
only when a directory appears or disappears; per-file trees live in the code.

## Root

| Path | What it holds |
| --- | --- |
| `packages/` | The six Dart packages that make up the SDK and CLI. |
| `extensions/` | The 34 bundled extensions (manifest, brick, docs, goldens). |
| `bricks/` | The `app_basic` project brick and `extension_template`. |
| `schemas/` | JSON schemas for `kiln.yaml`, the lockfile, manifests, migrations and the registry index. |
| `tool/` | Verification, generation and end-to-end tools run from the repo root. |
| `docs/` | Documentation and dated audit reports; start at `docs/README.md`. |
| `examples/` | Generated apps (`full_stack`, `minimal`, `backend_swap`, `custom_extension`). |
| `registry/` | Published extension index and archives. |
| `test/` | Repository-level tests for the workspace. |
| `bin/` | Local CLI executable (`kiln.exe`, rebuilt with `bin/rebuild.cmd`; not committed). |
| `website/` | Documentation site sources (not part of the SDK). |
| `build/`, `e2e_appwrite/`, `.dart_tool/` | Generated output; ignored by git. |

Root config: `pubspec.yaml`/`pubspec.lock`, `analysis_options.yaml`,
`.github/workflows`, `.vscode`, and the repository policies
(`CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `LICENSE`).

## `packages/`

| Package | Responsibility |
| --- | --- |
| `kiln_core` | Contracts, failures, registry/runtime, sessions, privacy. Entry: `lib/kiln_core.dart`; `lib/src/{contracts,errors,gate,privacy,runtime,session,util}`. |
| `kiln_extension_sdk` | Manifest parsing, resolution, renderer, transactional installer, native patches, migration. |
| `kiln_cli` | `kiln` commands plus the generated bundles (`lib/src/bundles/`) and the catalog. |
| `kiln_store` | Registry client, archive verification and publishing. |
| `kiln_testing` | Fakes, contract suites and the widget/test registry harness. |
| `kiln_lints` | Optional lint rules that keep generated apps on contracts. |

## `extensions/`

Every extension has the same shape: `extension.yaml` (manifest), `brick/`
(Mason template: `lib/`, `test/`, `.template` files), `docs/`, `README.md`,
`CHANGELOG.md`, and `test/goldens/rendered.json` (file hashes).

| Extension | Category | Purpose |
| --- | --- | --- |
| `analytics` | analytics | PostHog analytics behind consent and PII scrubbing. |
| `appwrite` | auth | Appwrite auth, social sign-in, database, storage and functions. |
| `appwrite_push` | notifications | FCM transport for the Appwrite backend. |
| `appwrite_push_native` | notifications | Appwrite Push (MQTT) transport without Firebase. |
| `biometric` | security | Biometric checks, app lock and protected storage. |
| `bloc` | state | Bloc state management with a feature layout. |
| `calendar` | calendar | Add events through the native calendar UI. |
| `codegen` | codegen | `json_serializable` + `freezed` through `build_runner`. |
| `connectivity` | connectivity | Network status and an offline guard middleware. |
| `crash_report` | crash | Sentry reporting behind consent, with redaction and breadcrumbs. |
| `deep_link` | deep_link | Incoming links with allowlisting, normalization and dedup. |
| `dio` | network | HTTP client and middleware pipeline. |
| `env` | config | Typed build-time configuration from `--dart-define`. |
| `firebase` | auth | Firebase Auth, Firestore and Cloud Storage. |
| `flavors` | flavor | Dart-level flavors and entry points. |
| `geolocation` | location | Device location reads and streams. |
| `go_router` | navigation | Routing, guards, route slots and link/notification mapping. |
| `http_cache` | network | Response cache with TTL, ETag and invalidation. |
| `http_retry` | network | Retry with backoff, budgets and cancellation. |
| `image_picker` | media | Camera/gallery picking with validation and upload handoff. |
| `l10n` | l10n | ARB localizations, locale selection and formatting. |
| `local_db` | database | Sembast document database with sync queue and backup. |
| `logger` | logging | Structured logging, redaction, rotating files, breadcrumbs. |
| `notifications` | notifications | Local notifications with channels, scheduling and taps. |
| `permission` | platform | Typed permission checks and rationale flow. |
| `remote_config` | config | Feature flags from any JSON endpoint, with last-known-good cache. |
| `rest_auth` | auth | Email/password auth against a REST API. |
| `riverpod` | state | Riverpod state management with a feature layout. |
| `secure_storage` | storage | Keychain/Keystore for secrets and tokens. |
| `share` | share | Native share sheet for text, links and files. |
| `social_login` | social | Google/Apple credentials for a social backend. |
| `storage` | storage | Key-value storage on `shared_preferences`, with migrations. |
| `supabase` | auth | Supabase auth, PostgREST, realtime and storage. |
| `theme` | theme | Colors, typography, tokens and light/dark mode. |

## `tool/`

| Tool | Purpose |
| --- | --- |
| `bundle.dart` | Regenerates `packages/kiln_cli/lib/src/bundles/` and `catalog.g.dart`. |
| `registry.dart` | Regenerates `registry/index.json` and the archives. |
| `gen_catalog_docs.dart` | Regenerates `docs/extensions/catalog.md`. |
| `check_metadata.dart` | Manifest ↔ rendered module metadata parity (AST-based). |
| `check_versions.dart` | Workspace and extension version consistency. |
| `check_docs.dart` | Documentation links and file references. |
| `check_drift.dart` | Brick ↔ golden/bundle drift. |
| `verify_extensions.dart` | Per-extension render, analyze, test and golden update (`--only`, `--update`). |
| `lint_extensions.dart` | Extension lint rules. |
| `appwrite_platform_probe.dart` | Renders the disposable Appwrite probe fixture. |
| `appwrite_e2e.dart`, `verify_http_stack.dart` | Live Appwrite suite and HTTP stack checks. |
| `e2e/` | Device probe templates and the loopback fixtures: Appwrite platform backend, push routing host, dio+cache composition, and their README. |

Fixtures land in `.dart_tool/` and are ignored; they are manual runs, not part of
`flutter test`.

## Generated artifacts

| Artifact | Produced by | Committed |
| --- | --- | --- |
| `packages/kiln_cli/lib/src/bundles/*.dart` | `tool/bundle.dart` | yes |
| `registry/index.json`, `registry/archives/*.tgz` | `tool/registry.dart` | yes |
| `docs/extensions/catalog.md` | `tool/gen_catalog_docs.dart` | yes |
| `extensions/*/test/goldens/rendered.json` | `tool/verify_extensions.dart --update` | yes |
| `bin/kiln.exe` | `bin/rebuild.cmd` | no |
| `.dart_tool/`, `build/`, `e2e_appwrite/` | Flutter/Dart and the probes | no |

Run the generators after changing a brick or manifest; the checks above fail when
an artifact is out of date.

## A generated application

`kiln create` renders `bricks/app_basic` and then each installed extension:

```
lib/
  app/            app_route.dart, app config modules
  core/           error handling, shared widgets
  extensions/     one directory per installed extension
  main.dart
test/             rendered extension tests and widget tests
android/ ios/ web/ macos/ windows/ linux/
```

Native setup (permissions, manifest entries, Info.plist keys, Podfile lines) is
applied by the installer and recorded in the transaction journal, not by hand.
