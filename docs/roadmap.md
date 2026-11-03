# Roadmap

## Fase 1 — Fondasi end-to-end (selesai)

- [x] Monorepo workspace, schema YAML, `.vscode`, root tooling.
- [x] `kiln_core`: kontrak, error, Registry, module graph, bootstrap, slot,
      sesi, consent, PII, clock, debouncer.
- [x] `kiln_testing`: fake per kontrak, contract suite, harness widget.
- [x] `kiln_extension_sdk`: manifest, validator, resolver, renderer Mason,
      installer transaksional, patch native, migrasi.
- [x] `kiln_cli`: create, add, remove, list, doctor, graph, info, rollback,
      config, cache, store, completion, ext new/validate/test/pack.
- [x] Brick `app_basic`, `extension_template`, dan extension `dio`.
- [x] Bundle generator dan `--check` untuk CI.
- [x] Bukti end-to-end: `kiln create` + `kiln add dio` + `flutter analyze` +
      `flutter test` pada proyek hasil generate.
- [x] Dokumentasi arsitektur, manifest, CLI, konsep, dan keputusan desain.

## Fase 2 — Extension inti

- [x] State management: `bloc`, `riverpod` dengan wrapper `app.wrappers`,
      session bridge, contoh counter, dan bootstrap test.
- [x] Jaringan: `http_retry` dan `http_cache` dengan priority pipeline
      (retry 20 sebelum cache 30), ETag, stale-while-revalidate, dan budget.
- [x] Storage: `storage`, `secure_storage`, dan `local_db` (Sembast,
      transaksi, watcher, backup, sync queue, migrasi, dan enkripsi opsional).
- [x] Auth/backend: `rest_auth`, `appwrite`, `firebase`, `supabase`,
      `social_login`, `biometric` dengan gateway yang bisa di-fake, sesi,
      remote database, file storage, app lock, dan test kontrak.
- [x] Navigasi/UI: `go_router`, `deep_link`, `theme`, `l10n` dengan slot
      route, guard sesi, pemetaan tautan/tap, token desain, dan locale hidup.
- [x] Platform: `permission`, `connectivity`, `notifications`, `image_picker`
      dengan gateway yang bisa di-fake, widget siap pakai, dan `e2e_platform`
      yang lolos analyze, test, dan doctor.
- [x] Tooling: `env`, `flavors`, `logger`, `analytics` dengan nilai
      build-time, entry point per flavor, sink/redaksi, consent gate, dan PII.
- [x] Setiap extension: README, CHANGELOG, docs, test manifest/render/analyze,
      contract test bila punya kontrak.

## Fase 3 — Registry dan distribusi

- [x] Implementasi `kiln_store`: registry client, version resolver, checksum,
      trust policy, archive pack/unpack, offline cache, publisher.
- [x] Registry index, arsip versi, dan generator registry.
- [x] `kiln store search/info/install`, upgrade multi-versi dengan migration
      runner.
- [x] `kiln ext publish` dan `kiln ext pack` versi registry.
- [x] `kiln_lints` dengan lima rule dasar, berjalan di analyzer 8 sampai
      `custom_lint_builder` mendukung analyzer 14.

## Fase 4 — Kualitas dan skala

- [x] Workflow extension matrix, smoke nightly, drift check, docs build,
      release publish.
- [x] Golden render per extension dan analyze fixture bersama lewat
      `tool/verify_extensions.dart`.
- [x] `examples/minimal`, `examples/full_stack`, `examples/backend_swap`,
      `examples/custom_extension`.
- [x] Lint custom: no cross-extension import, prefer contract, no plugin in
      features, no edit generated files, require failure handling.

## Diparkir sampai ada keputusan

- `crash_report`: vendor belum dipilih; gateway Sentry hanya contoh.
- `codegen`: generator pilihan (`json_serializable`/`freezed`) belum final.
- Model distribusi registry: Git URL, registry terpisah, atau keduanya.

## Keputusan yang sudah diambil

- Akses layanan lewat Registry; tidak ada fasad statis/global.
- Kontrak melempar `Failure`; `Result<T>` adalah helper feature.
- `http.interceptors` membawa `HttpMiddleware` dari `kiln_core`, bukan tipe dio.
- Lockfile versi 2: peta path ke hash, patch, dan manual step.
- Semua perubahan instalasi lewat transaksi dengan jurnal dan rollback.
