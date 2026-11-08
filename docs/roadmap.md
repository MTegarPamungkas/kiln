# Roadmap

## Phase 1 — End-to-end foundation (done)

- [x] Monorepo workspace, YAML schemas, `.vscode`, root tooling.
- [x] `kiln_core`: contracts, errors, Registry, module graph, bootstrap, slots,
      session, consent, PII, clock, debouncer.
- [x] `kiln_testing`: fakes per contract, contract suite, widget harness.
- [x] `kiln_extension_sdk`: manifest, validator, resolver, Mason renderer,
      transactional installer, native patches, migrations.
- [x] `kiln_cli`: create, add, remove, list, doctor, graph, info, rollback,
      config, cache, store, completion, ext new/validate/test/pack.
- [x] Bricks `app_basic`, `extension_template`, and the `dio` extension.
- [x] Bundle generator and `--check` for CI.
- [x] End-to-end proof: `kiln create` + `kiln add dio` + `flutter analyze` +
      `flutter test` on the generated project.
- [x] Documentation for architecture, manifest, CLI, concepts, and design
      decisions.

## Phase 2 — Core extensions

- [x] State management: `bloc`, `riverpod` with the `app.wrappers` wrapper,
      session bridge, a clean-architecture `notes` example, and a wrapper test.
- [x] Networking: `http_retry` and `http_cache` with pipeline priority
      (retry 20 before cache 30), ETag, stale-while-revalidate, and budget.
- [x] Storage: `storage`, `secure_storage`, and `local_db` (Sembast,
      transactions, watchers, backup, sync queue, migrations, and optional
      encryption).
- [x] Auth/backend: `rest_auth`, `appwrite`, `firebase`, `supabase`,
      `social_login`, `biometric` with fakeable gateways, sessions, remote
      databases, file storage, app lock, and contract tests.
- [x] Navigation/UI: `go_router`, `deep_link`, `theme`, `l10n` with route slots,
      session guards, link/tap mapping, design tokens, and live locale.
- [x] Platform: `permission`, `connectivity`, `notifications`, `image_picker`
      with fakeable gateways, ready-to-use widgets, and `e2e_platform` that
      passes analyze, test, and doctor.
- [x] Tooling: `env`, `flavors`, `logger`, `analytics` with build-time values,
      per-flavor entry points, sinks/redaction, consent gate, and PII.
- [x] Every extension: README, CHANGELOG, docs, manifest/render/analyze tests,
      and contract tests when it owns a contract.

## Phase 3 — Registry and distribution

- [x] `kiln_store` implementation: registry client, version resolver, checksum,
      trust policy, archive pack/unpack, offline cache, publisher.
- [x] Registry index, version archives, and registry generator.
- [x] `kiln store search/info/install`, multi-version upgrade with a migration
      runner.
- [x] `kiln ext publish` and the registry version of `kiln ext pack`.
- [x] `kiln_lints` with five base rules, running on analyzer 8 until
      `custom_lint_builder` supports analyzer 14.

## Phase 4 — Quality and scale

- [x] Extension matrix workflow, nightly smoke, drift check, docs build,
      release publish.
- [x] Per-extension golden render and shared fixture analyze through
      `tool/verify_extensions.dart`.
- [x] `examples/minimal`, `examples/full_stack`, `examples/backend_swap`,
      `examples/custom_extension`.
- [x] Custom lints: no cross-extension import, prefer contract, no plugin in
      features, no edit generated files, require failure handling.

## Phase 5 — Device-aware support audit (done)

- [x] `SupportInfo`, `SupportState`, `SupportRegistry`, and `KilnModule.support`.
- [x] Bootstrap probes runtime support, records it, and skips `ready()` for
      unsupported extensions.
- [x] All runtime extensions report platform, device, and configuration
      readiness; unsupported calls return typed failures instead of blocking
      startup.
- [x] `kiln create` defaults to the minimal template; `go_router` sample shell
      and auth redirect are opt-in.
- [x] Native setup for permission kinds, plus `android.compile_sdk` patches.
- [x] Runtime support report verified on an Android emulator.

## Phase 6 — Crash reporting (Sentry)

- [x] `crash_report` implements the `kiln_core` `CrashReporter` contract over
  `sentry_flutter`, with the SDK isolated to a single fakeable gateway file.
- [x] A decorator chain (`Safe` → `ConsentGate` → `PiiScrubbing` → vendor/noop)
  makes reporting failure-safe, opt-in, and PII-redacted.
- [x] Gate verbs added (`reportBreadcrumb`, `setReportUser`, `setReportContext`,
  `crashReportsConsented`) alongside the `reportError`/`reportMessage` verbs that
  already live in `kiln_core`.
- [x] The logger's `BreadcrumbSink` forwards warnings and errors into the
  reporter and inherits its consent and redaction automatically.
- [x] Manifest, brick, goldens, registry, catalog, docs, and the kiln_testing
  `crashReporterContract` suite all pass.

## Phase 7 — Code generation

- [x] `codegen` wires `json_serializable` + `freezed` into a project with a
  shared `build.yaml`, epoch/URI/Duration `JsonConverter`s, and a sample
  freezed+JSON model (generated output committed for CI-safe analysis).
- [x] First extension to use install hooks: a `post_gen` hook runs
  `build_runner`, gated by `HookPolicy` so it only executes for an approved
  official-tier install.
- [x] A `generators` multi-select prompt lets apps enable one or both.
- [x] Manifest, brick, goldens, registry, catalog, docs, and a real
  `flutter analyze` of the rendered model all pass.

## Phase 8 — Remote config

- [x] `RemoteConfig` contract added to `kiln_core` with typed synchronous reads,
  `setDefaults`, `fetch`/`activate`, and a `changes` stream; `Gate.remoteConfig`
  and a `fetchRemoteConfig` verb expose it.
- [x] `FakeRemoteConfig` and a shared `remoteConfigContract` suite in
  `kiln_testing`, auto-registered in the default test registry.
- [x] `remote_config` extension: a vendor-neutral gateway reading a flat JSON
  object over `package:http`, with an empty endpoint serving only defaults.
- [x] Gate ergonomics (`featureEnabled`, typed reads, `setRemoteDefaults`,
  `remoteConfigChanges`). Firebase/LaunchDarkly can drop in as a gateway.

## Parked until a decision is made

- Deferred crash_report refinements: an expected-Failure classifier, a
  release-info reader, and a non-production crash-test trigger (error
  deduplication and HTTP breadcrumb middleware are now shipped in Phase 6).
- Registry distribution model: Git URL, separate registry, or both.

## Decisions already made

- Service access goes through the Registry; there is no static/global facade.
- Contracts throw `Failure`; `Result<T>` is a feature helper.
- `http.interceptors` carries `HttpMiddleware` from `kiln_core`, not dio types.
- Lockfile version 2: maps paths to hashes, patches, and manual steps.
- Every installation change goes through a transaction with a journal and
  rollback.
