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
      session bridge, counter example, and bootstrap test.
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
- [x] All 26 extensions report platform, device, and configuration readiness;
      unsupported calls return typed failures instead of blocking startup.
- [x] `kiln create` defaults to the minimal template; `go_router` sample shell
      and auth redirect are opt-in.
- [x] Native setup for permission kinds, plus `android.compile_sdk` patches.
- [x] Runtime support report verified on an Android emulator.

## Parked until a decision is made

- `crash_report`: no vendor chosen yet; the Sentry gateway is only a sample.
- `codegen`: the preferred generator (`json_serializable`/`freezed`) is not
  final.
- Registry distribution model: Git URL, separate registry, or both.

## Decisions already made

- Service access goes through the Registry; there is no static/global facade.
- Contracts throw `Failure`; `Result<T>` is a feature helper.
- `http.interceptors` carries `HttpMiddleware` from `kiln_core`, not dio types.
- Lockfile version 2: maps paths to hashes, patches, and manual steps.
- Every installation change goes through a transaction with a journal and
  rollback.
