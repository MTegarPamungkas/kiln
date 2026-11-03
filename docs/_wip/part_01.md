## Root monorepo

Root memuat semua yang bukan kode package: CI, dokumentasi, schema YAML,
template proyek, contoh, registry extension, dan skrip rilis. Isi `extensions/`
dan `packages/` diuraikan di bagian berikutnya.

```text
kiln/
├─ .github/                                  # konfigurasi GitHub: workflow CI, template issue dan PR, pemilik kode
│  ├─ ISSUE_TEMPLATE/                        # formulir issue yang bisa dipilih kontributor di GitHub
│  │  ├─ bug_report.yml                      # formulir untuk melaporkan bug di Kiln
│  │  ├─ extension_request.yml               # formulir untuk mengusulkan extension ke katalog Kiln
│  │  └─ config.yml                          # mengatur pilihan formulir issue dan tautan kontak
│  ├─ workflows/                             # workflow GitHub Actions untuk CI, rilis, dan pemeriksaan terjadwal
│  │  ├─ ci.yaml                             # pipeline CI utama: analyze dan test di setiap push dan PR
│  │  ├─ extensions.yaml                     # matrix CI yang hanya menguji extension yang berubah
│  │  ├─ bundles_check.yaml                  # menggagalkan build bila bundles belum di-generate ulang
│  │  ├─ smoke.yaml                          # nightly: create, add semua extension, lalu build apk dan ios
│  │  ├─ drift.yaml                          # nightly: mengecek versi terbaru package pihak ketiga yang dipakai extension
│  │  ├─ docs.yaml                           # membangun dokumentasi dari folder docs/
│  │  └─ release.yaml                        # publish ke pub.dev dan update registry
│  ├─ CODEOWNERS                             # daftar pemilik kode yang otomatis diminta me-review PR
│  ├─ dependabot.yml                         # jadwal update dependensi otomatis oleh Dependabot
│  └─ PULL_REQUEST_TEMPLATE.md               # template deskripsi dan checklist untuk setiap PR
├─ .vscode/                                  # pengaturan VS Code bersama untuk kontributor repo
│  ├─ settings.json                          # memasang schemas/ ke extension.yaml, kiln.yaml, dan kiln.lock.yaml
│  └─ extensions.json                        # rekomendasi ekstensi Dart dan YAML
├─ docs/                                     # dokumentasi untuk pengguna dan kontributor Kiln
│  ├─ architecture.md                        # gambaran arsitektur Kiln dan hubungan antar package
│  ├─ extension-manifest.md                  # spesifikasi lengkap field manifest extension.yaml
│  ├─ roadmap.md                             # rencana fase pengembangan Kiln
│  ├─ folder-structure.md                    # cetak biru struktur folder Kiln (dokumen ini)
│  ├─ getting-started.md                     # panduan memasang Kiln dan membuat aplikasi pertama
│  ├─ concepts/                              # penjelasan konsep inti Kiln
│  │  ├─ contracts-and-capabilities.md       # kontrak di kiln_core dan kapabilitas yang disediakan extension
│  │  ├─ slots.md                            # slot sebagai titik sambung antar extension
│  │  ├─ lockfile-and-ownership.md           # isi kiln.lock.yaml dan kepemilikan file oleh extension
│  │  ├─ transactions-and-rollback.md        # transaksi pemasangan dan cara membalikkannya lewat jurnal
│  │  ├─ native-patches.md                   # patch file native platform oleh extension
│  │  ├─ compatibility.md                    # aturan kompatibilitas versi Kiln, extension, dan package
│  │  └─ security-model.md                   # model keamanan: hook, trust tier, dan checksum
│  ├─ cli/                                   # dokumentasi perintah CLI kiln
│  │  └─ reference.md                        # referensi perintah, flag, dan contoh pemakaian kiln
│  ├─ extensions/                            # dokumentasi extension: katalog, cara menulis, uji, dan terbit
│  │  ├─ catalog.md                          # generate dari semua extension.yaml, jangan diedit
│  │  ├─ writing-an-extension.md             # panduan menulis extension dari manifest sampai brick
│  │  ├─ testing-extensions.md               # cara menguji extension: manifest, render, analyze, dan golden
│  │  ├─ trust-tiers.md                      # tingkat kepercayaan extension dan konsekuensinya bagi user
│  │  └─ publishing.md                       # langkah menerbitkan extension ke registry
│  ├─ guides/                                # panduan langkah demi langkah untuk skenario umum
│  │  ├─ swap-backend.md                     # mengganti backend tanpa mengubah kode aplikasi
│  │  ├─ migrate-bloc-to-riverpod.md         # migrasi state management dari bloc ke riverpod
│  │  ├─ add-offline-support.md              # menambahkan dukungan offline ke aplikasi
│  │  └─ setup-flavors-and-env.md            # menyiapkan flavor dan file env per lingkungan
│  └─ adr/                                   # catatan keputusan arsitektur
│     ├─ 0001-never-edit-user-code.md        # keputusan: Kiln tidak pernah mengedit kode milik user
│     ├─ 0002-capabilities-not-ids.md        # keputusan: extension bergantung pada kapabilitas, bukan id extension
│     ├─ 0003-hooks-and-trust.md             # keputusan: hook dijalankan dengan konfirmasi berdasarkan trust tier
│     ├─ 0004-transactions-and-journal.md    # keputusan: perubahan diterapkan lewat transaksi dengan jurnal
│     └─ 0005-checksums-and-registry.md      # keputusan: checksum arsip dan registry sebagai sumber extension
├─ schemas/                                  # JSON Schema untuk validasi dan autocomplete YAML di IDE
│  ├─ extension.schema.json                  # memvalidasi manifest extension.yaml
│  ├─ kiln.schema.json                       # memvalidasi konfigurasi proyek kiln.yaml
│  ├─ kiln-lock.schema.json                  # memvalidasi lockfile kiln.lock.yaml
│  ├─ migration.schema.json                  # memvalidasi file migration di extensions/<id>/migrations
│  └─ registry-index.schema.json             # memvalidasi registry/index.json
├─ bricks/                                   # template Mason untuk proyek aplikasi dan extension
│  ├─ app_basic/                             # brick proyek aplikasi dasar yang dipakai kiln create
│  │  ├─ brick.yaml                          # metadata brick app_basic dan variabel prompt proyek
│  │  ├─ hooks/                              # hook Mason yang berjalan sebelum dan sesudah generate
│  │  │  ├─ pubspec.yaml                     # dependensi untuk menjalankan hook
│  │  │  ├─ pre_gen.dart                     # memvalidasi nama app, org, dan bentrok folder tujuan
│  │  │  └─ post_gen.dart                    # menjalankan flutter create, menambah kiln_core, pub get, format, dan git init
│  │  └─ __brick__/                          # isi template yang dirender menjadi proyek user
│  │     ├─ README.md                        # petunjuk menjalankan dan mengembangkan proyek hasil generate
│  │     ├─ kiln.yaml                        # konfigurasi proyek Kiln yang dibaca CLI
│  │     ├─ analysis_options.yaml            # aturan analyzer Dart untuk proyek hasil generate
│  │     ├─ .gitignore                       # mengabaikan .kiln/backups, .kiln/journal, .kiln/logs, dan env/*.json kecuali *.example.json
│  │     ├─ lib/                             # kode sumber aplikasi
│  │     │  ├─ main.dart                     # titik masuk aplikasi: menjalankan KilnBootstrap lalu KilnApp
│  │     │  ├─ app/                          # widget root dan kerangka aplikasi
│  │     │  │  ├─ app.dart                   # KilnApp, widget root yang memasang RegistryScope
│  │     │  │  ├─ registry_scope.dart        # RegistryScope: menyediakan Registry ke pohon widget
│  │     │  │  ├─ app_shell.dart             # membangun MaterialApp (theme, locale, router dari Registry bila ada), menerapkan slot app.wrappers
│  │     │  │  ├─ error_screen.dart          # layar yang ditampilkan saat bootstrap gagal
│  │     │  │  ├─ app_wrappers.dart          # slot bawaan app.wrappers, tipe AppWrapper = Widget Function(BuildContext, Widget)
│  │     │  │  └─ app_route.dart             # AppRoute netral (path, name, builder) untuk slot router.routes, tanpa impor go_router
│  │     │  └─ core/                         # komponen inti aplikasi: l10n, theme, dan penanganan error
│  │     │     ├─ l10n/                      # lokalisasi bawaan aplikasi dan titik sambung extension l10n
│  │     │     │  ├─ app_localizations_config.dart  # konfigurasi bertipe: AppLocalizationsConfig, titik sambung extension l10n
│  │     │     │  └─ app_strings.dart        # teks UI bawaan aplikasi bila tidak ada AppLocalizationsConfig di Registry
│  │     │     ├─ theme/                     # theme bawaan aplikasi dan titik sambung extension theme
│  │     │     │  ├─ app_theme_config.dart   # konfigurasi bertipe: AppThemeConfig, titik sambung extension theme
│  │     │     │  └─ app_theme.dart          # theme bawaan aplikasi bila tidak ada AppThemeConfig di Registry
│  │     │     └─ error/                     # penanganan error global dan pesan error untuk user
│  │     │        ├─ global_error_handler.dart  # meneruskan error Flutter dan platform ke Logger, lalu CrashReporter bila terpasang
│  │     │        └─ failure_presenter.dart  # mengubah Failure menjadi pesan ramah user, teks dari FailureMessages l10n bila terpasang
│  │     └─ test/                            # test yang berjalan di aplikasi hasil generate
│  │        └─ app/                          # test untuk kerangka aplikasi di lib/app
│  │           └─ app_smoke_test.dart        # menguji bahwa KilnApp bisa dirender tanpa error
│  └─ extension_template/                    # kerangka extension kosong, dipakai kiln ext new
│     ├─ brick.yaml                          # variabel brick: id, name, category, provides, requires, with_hooks, with_native_patch
│     └─ __brick__/                          # isi template yang dirender menjadi folder extension
│        └─ {{id.snakeCase()}}/              # folder extension hasil render, dinamai dari id dalam snake_case
│           ├─ extension.yaml                # manifest: diisi dari variabel id, name, category, provides, dan requires
│           ├─ README.md                     # penjelasan singkat extension: fungsi, cara pasang, dan opsi
│           ├─ CHANGELOG.md                  # riwayat perubahan per versi extension
│           ├─ docs/                         # dokumentasi tambahan extension
│           │  └─ {{id.paramCase()}}.md      # dokumentasi topik extension, nama file dari id dalam paramCase
│           ├─ test/                         # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│           │  ├─ manifest_test.dart         # menguji bahwa extension.yaml valid terhadap extension.schema.json
│           │  ├─ render_test.dart           # menguji bahwa render brick ke folder temp cocok dengan golden
│           │  └─ analyze_test.dart          # menguji bahwa hasil render lolos dart analyze tanpa peringatan
│           └─ brick/                        # brick Mason milik extension, dirender ke proyek user lewat kiln add
│              ├─ brick.yaml                 # metadata brick extension dan variabel prompt-nya
│              ├─ hooks/                     # hook Mason, dibuat bila with_hooks
│              │  ├─ pubspec.yaml            # dependensi untuk menjalankan hook
│              │  ├─ pre_gen.dart            # memvalidasi input sebelum brick dirender
│              │  └─ post_gen.dart           # menjalankan langkah lanjutan setelah brick dirender
│              └─ __brick__/                 # isi brick yang dirender ke proyek user
│                 ├─ lib/extensions/{{id.snakeCase()}}/  # kode extension yang masuk ke lib/ proyek user
│                 │  ├─ {{id.snakeCase()}}.dart          # fasad statis dengan API pendek untuk dipakai kode aplikasi
│                 │  ├─ {{id.snakeCase()}}_module.dart   # mendaftarkan layanan extension ke Registry
│                 │  ├─ {{id.snakeCase()}}_config.dart   # konfigurasi bertipe: nilai yang diisi dari prompt
│                 │  └─ {{id.snakeCase()}}_failure_mapper.dart  # mengubah error package pihak ketiga menjadi Failure
│                 └─ test/extensions/{{id.snakeCase()}}/  # test extension yang masuk ke test/ proyek user
│                    ├─ {{id.snakeCase()}}_module_test.dart          # menguji bahwa module mendaftarkan layanannya ke Registry
│                    └─ {{id.snakeCase()}}_failure_mapper_test.dart  # menguji bahwa error pihak ketiga dipetakan ke Failure yang tepat
├─ extensions/                               # 29 folder extension, diuraikan di bagian Extension
├─ examples/                                 # proyek contoh hasil generate sebagai referensi pemakaian Kiln
│  ├─ minimal/                               # hasil kiln create tanpa extension
│  │  ├─ kiln.yaml                           # konfigurasi proyek tanpa extension
│  │  ├─ kiln.lock.yaml                      # lockfile tanpa extension terpasang
│  │  ├─ pubspec.yaml                        # dependensi proyek minimal tanpa package extension
│  │  ├─ lib/                                # kode aplikasi minimal hasil generate
│  │  └─ test/                               # test bawaan aplikasi minimal
│  ├─ full_stack/                            # memasang bloc, dio, http_retry, rest_auth, secure_storage, go_router, theme, l10n, env, logger
│  │  ├─ kiln.yaml                           # konfigurasi proyek dengan semua extension terpasang
│  │  ├─ kiln.lock.yaml                      # lockfile yang mencatat versi dan file milik tiap extension
│  │  ├─ pubspec.yaml                        # dependensi proyek, termasuk package dari tiap extension
│  │  ├─ lib/                                # kode aplikasi beserta kode extension di lib/extensions
│  │  └─ test/                               # test aplikasi beserta test extension di test/extensions
│  ├─ backend_swap/                          # membuktikan backend bisa diganti tanpa mengubah kode app
│  │  ├─ README.md                           # menjelaskan skenario ganti backend dan cara membandingkan kedua varian
│  │  ├─ with_appwrite/                      # varian proyek dengan backend Appwrite
│  │  └─ with_supabase/                      # varian proyek dengan backend Supabase; hanya kiln.yaml dan lib/extensions yang berbeda
│  └─ custom_extension/                      # hasil kiln ext new: contoh extension komunitas lengkap
├─ registry/                                 # indeks dan metadata versi extension, dihasilkan tool/build_registry.dart
│  ├─ index.json                             # daftar extension: id, versi terbaru, dan tier
│  ├─ README.md                              # penjelasan format registry dan cara memakainya
│  └─ extensions/                            # metadata rilis, satu folder per extension
│     ├─ dio/                                # metadata rilis extension dio, satu json per versi
│     │  ├─ 1.0.0.json                       # metadata rilis 1.0.0: url arsip, sha256, requires, compatibility
│     │  └─ 1.1.0.json                       # metadata rilis 1.1.0 dengan field yang sama
│     └─ <id>/                               # satu folder per extension, berisi satu json per versi
├─ tool/                                     # skrip Dart untuk bundling, registry, pemeriksaan, dan rilis
│  ├─ bundle.dart                            # membundel semua brick dengan mason bundle, flag --check untuk CI
│  ├─ smoke_test.dart                        # menguji alur create dan add semua extension sampai bisa di-build
│  ├─ build_registry.dart                    # menghasilkan registry/index.json dan json versi tiap extension
│  ├─ check_drift.dart                       # membandingkan constraint extension dengan versi terbaru di pub.dev
│  ├─ lint_extensions.dart                   # menjalankan kiln ext validate ke semua extension
│  ├─ gen_catalog_docs.dart                  # menulis docs/extensions/catalog.md dari semua extension.yaml
│  └─ release.dart                           # menaikkan versi, menulis changelog, dan membuat tag
├─ packages/                                 # 6 package Dart, diuraikan per package di bawah
│  ├─ kiln_cli/                              # CLI kiln: perintah create, add, upgrade, rollback, dan doctor
│  ├─ kiln_core/                             # kontrak, model error, runtime modul, state sesi, dan utilitas privasi
│  ├─ kiln_extension_sdk/                    # mesin kiln add: baca manifest, hitung rencana, render brick, terapkan transaksi
│  ├─ kiln_store/                            # klien registry: ambil index, pilih versi, verifikasi checksum, trust policy
│  ├─ kiln_testing/                          # fake per kontrak, suite kontrak, dan harness test
│  └─ kiln_lints/                            # aturan lint custom_lint untuk proyek Kiln, opsional (Fase 6)
├─ CONTRIBUTING.md                           # panduan kontribusi: setup repo, gaya kode, dan alur PR
├─ SECURITY.md                               # kebijakan keamanan dan cara melaporkan kerentanan
├─ CODE_OF_CONDUCT.md                        # aturan perilaku komunitas kontributor
├─ LICENSE                                   # teks lisensi proyek Kiln
├─ .gitignore                                # mengabaikan artefak build dan file lokal di repo
├─ analysis_options.yaml                     # aturan analyzer Dart bersama untuk seluruh monorepo
├─ pubspec.yaml                              # dependensi skrip tool/ dan tooling dev monorepo
├─ pubspec.lock                              # mengunci versi dependensi root monorepo
└─ README.md                                 # pengantar proyek Kiln dan tautan ke dokumentasi
```

