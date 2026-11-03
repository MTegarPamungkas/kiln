### crash_report

Roadmap masih mem-parkir extension ini karena vendor belum dipilih, jadi
gambar ini memakai **Sentry sebagai contoh** di balik `crash_report_gateway.dart`.
Mengganti vendor berarti mengganti satu gateway, bukan lapisan di atasnya.

```text
extensions/crash_report/
├─ extension.yaml                            # manifest: provides: crash_reporter · category: crash_reporting · exclusive · prompts: dsn (secret), sample_rate · android: INTERNET
├─ README.md                                 # pengantar extension: fungsi, cara pasang, dan opsi konfigurasi
├─ CHANGELOG.md                              # riwayat perubahan extension per versi
├─ docs/                                     # dokumentasi crash reporting, pemilihan vendor, simbol, dan privasi
│  ├─ crash-reporting.md                     # gambaran umum crash reporting dan lapisan decorator di atas gateway
│  ├─ choosing-a-vendor.md                   # kriteria memilih vendor dan cara mengganti gateway
│  ├─ symbols-and-obfuscation.md             # cara mengunggah simbol di CI dan memakai --split-debug-info
│  └─ privacy-and-consent.md                 # panduan privasi: izin pengguna lewat ConsentController dan penyaringan PII
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                    # brick Mason: template yang dirender ke aplikasi user
   ├─ brick.yaml                             # metadata brick Mason: nama, versi, dan variabel dari prompt
   └─ __brick__/                             # isi template yang disalin ke aplikasi user
      ├─ lib/extensions/crash_report/               # kode runtime extension di aplikasi user
      │  ├─ crash_report_module.dart                # mendaftarkan CrashReporter beserta decorator-nya ke Registry
      │  ├─ crash_report_config.dart                # konfigurasi bertipe: dsn, environment dari AppFlavor, release, sample rate
      │  ├─ crash_report_gateway.dart               # interface vendor yang bisa di-fake di test: captureError, addBreadcrumb, setUser, setContext
      │  ├─ sentry_crash_gateway.dart               # membungkus sentry_flutter sebagai SdkCrashGateway contoh agar bisa di-fake di test
      │  ├─ crash_report_failure_mapper.dart        # mengubah error inisialisasi vendor menjadi Failure(unavailable), app tetap bisa start
      │  ├─ safe_crash_reporter.dart                # decorator: tidak pernah melempar, kegagalan gateway dicatat sekali ke Logger
      │  ├─ consent_gate_crash_reporter.dart        # decorator: laporan sebelum izin ConsentController dibuang atau ditahan sesuai konfigurasi
      │  ├─ pii_scrubbing_crash_reporter.dart       # decorator: menerapkan PiiRedactor pada pesan, breadcrumb, konteks, dan identitas user
      │  ├─ failure_classifier.dart                 # menandai Failure yang diharapkan (network, cancelled, validation) agar tidak dilaporkan
      │  ├─ error_deduplicator.dart                 # membatasi laju error identik yang berulang, memakai Clock
      │  ├─ release_info.dart                       # menyediakan versi dan build number untuk mengelompokkan laporan
      │  ├─ breadcrumb_recorder.dart                # mencatat navigasi, konektivitas, dan sesi sebagai breadcrumb lewat kontrak (readOrNull)
      │  ├─ http_breadcrumb_middleware.dart         # contributes: http.interceptors (when: [http_pipeline]), tanpa badan dan header sensitif
      │  └─ crash_test_trigger.dart                 # tombol uji kirim crash, hanya di flavor non-production
      └─ test/extensions/crash_report/              # test yang berjalan di aplikasi user untuk kode extension ini
         ├─ crash_report_module_test.dart           # menguji bahwa module mendaftarkan CrashReporter berlapis decorator ke Registry
         ├─ crash_report_config_test.dart           # menguji pembacaan dsn, environment dari AppFlavor, release, dan sample rate
         ├─ crash_report_failure_mapper_test.dart   # menguji bahwa error inisialisasi vendor menjadi Failure(unavailable)
         ├─ safe_crash_reporter_test.dart           # menguji bahwa kegagalan gateway tidak dilempar dan dicatat sekali ke Logger
         ├─ consent_gate_crash_reporter_test.dart   # menguji bahwa laporan sebelum izin dibuang atau ditahan sesuai konfigurasi
         ├─ pii_scrubbing_crash_reporter_test.dart  # menguji bahwa PiiRedactor diterapkan pada pesan, breadcrumb, konteks, dan identitas user
         ├─ failure_classifier_test.dart            # menguji bahwa Failure network, cancelled, dan validation tidak dilaporkan sebagai crash
         ├─ error_deduplicator_test.dart            # menguji bahwa error identik berulang dibatasi lajunya dengan Clock fake
         ├─ release_info_test.dart                  # menguji bahwa versi dan build number terbaca untuk pengelompokan laporan
         ├─ breadcrumb_recorder_test.dart           # menguji pencatatan breadcrumb navigasi, konektivitas, dan sesi lewat kontrak
         ├─ http_breadcrumb_middleware_test.dart    # menguji bahwa breadcrumb HTTP tidak memuat badan dan header sensitif
         ├─ crash_test_trigger_test.dart            # menguji bahwa tombol uji crash hanya muncul di flavor non-production
         └─ crash_reporter_contract_test.dart       # menjalankan suite kontrak CrashReporter dari kiln_testing ke implementasi ini
```

### ci

```text
extensions/ci/
├─ extension.yaml                            # manifest: provides: ci · category: ci · exclusive · prompts: flutter_version (default stable), build_artifacts (bool), coverage_threshold
├─ README.md                                 # pengantar extension: fungsi, cara pasang, dan opsi konfigurasi
├─ CHANGELOG.md                              # riwayat perubahan extension per versi
├─ docs/                                     # dokumentasi CI: alur workflow, secret yang dibutuhkan, dan unggah simbol
│  ├─ ci.md                                  # panduan workflow CI: format, analyze, test, dan batas coverage
│  ├─ required-secrets.md                    # nama secret yang dibutuhkan workflow dan cara membuatnya
│  └─ symbols-and-release-notes.md           # langkah unggah simbol crash_report bila dipasang, dan batas extension ini
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                    # brick Mason: template yang dirender ke aplikasi user
   ├─ brick.yaml                             # metadata brick Mason: nama, versi, dan variabel dari prompt
   └─ __brick__/                             # isi template yang disalin ke aplikasi user
      ├─ .github/                            # konfigurasi GitHub di aplikasi user: workflow, dependabot, template PR
      │  ├─ workflows/                       # workflow GitHub Actions yang dijalankan di CI
      │  │  ├─ ci.yaml                       # menjalankan format, analyze, dan test dengan batas coverage
      │  │  ├─ build.yaml                    # membangun apk dan web sebagai artifact, ios --no-codesign di runner macOS
      │  │  └─ kiln_doctor.yaml              # menjalankan kiln doctor --json, gagal bila hash, lockfile, atau registrasi tidak sinkron
      │  ├─ dependabot.yml                   # konfigurasi Dependabot untuk pub dan github-actions, mingguan
      │  └─ PULL_REQUEST_TEMPLATE.md         # templat deskripsi pull request yang diisi kontributor
      └─ test/extensions/ci/                 # test yang memeriksa workflow dan konfigurasi CI hasil render di aplikasi user
         ├─ ci_workflow_test.dart            # menguji bahwa ci.yaml menjalankan format, analyze, dan test dengan batas coverage
         ├─ build_workflow_test.dart         # menguji bahwa build.yaml membangun apk dan web, serta ios tanpa codesign
         ├─ kiln_doctor_workflow_test.dart   # menguji bahwa kiln_doctor.yaml menjalankan kiln doctor --json dan gagal bila tidak sinkron
         └─ dependabot_config_test.dart      # menguji bahwa dependabot.yml memantau pub dan github-actions setiap minggu
```

### codegen

Extension ini satu-satunya yang butuh hook sebagai bagian inti alurnya
(menjalankan `build_runner`). Roadmap mem-parkirnya sampai kontrak kode
generate-nya jelas; gambar ini mengusulkan `json_serializable` dan `freezed`
sebagai pilihan awal.

```text
extensions/codegen/
├─ extension.yaml                            # manifest: provides: codegen · category: codegen · exclusive · prompts: generators (multi-pilih) · deps: json_annotation, freezed_annotation
├─ README.md                                 # pengantar extension: fungsi, cara pasang, dan opsi konfigurasi
├─ CHANGELOG.md                              # riwayat perubahan extension per versi
├─ docs/                                     # dokumentasi codegen: alur build_runner, model JSON, dan pemecahan masalah
│  ├─ codegen.md                             # gambaran umum codegen dan cara memakai generator terpilih
│  ├─ build-runner-workflow.md               # cara build sekali, mode watch, dan apa saja yang di-commit
│  ├─ json-models.md                         # cara menulis model JSON dengan json_serializable dan freezed
│  └─ troubleshooting.md                     # mengatasi konflik output dan masalah versi analyzer
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                    # brick Mason: template yang dirender ke aplikasi user
   ├─ brick.yaml                             # metadata brick Mason: nama, versi, dan variabel dari prompt
   ├─ hooks/                                 # hook Mason yang berjalan sebelum dan sesudah render
   │  ├─ pubspec.yaml                        # dependensi paket hook pre_gen dan post_gen
   │  ├─ pre_gen.dart                        # memeriksa build.yaml milik user di folder tujuan sebelum render
   │  └─ post_gen.dart                       # menjalankan build_runner build --delete-conflicting-outputs, gagal hanya memberi peringatan
   └─ __brick__/                             # isi template yang disalin ke aplikasi user
      ├─ build.yaml                          # mengatur opsi json_serializable: explicit_to_json dan field_rename snake
      ├─ lib/extensions/codegen/             # kode extension di aplikasi user: converter dan model contoh
      │  ├─ json_converters.dart             # mengonversi DateTime epoch, Uri, dan Duration lewat @JsonKey
      │  └─ example/                         # model contoh beserta hasil generate-nya
      │     ├─ example_model.dart            # mendefinisikan model contoh dengan @freezed dan @JsonSerializable
      │     ├─ example_model.g.dart          # generate oleh build_runner, jangan diedit
      │     └─ example_model.freezed.dart    # generate oleh build_runner, jangan diedit
      └─ test/extensions/codegen/            # test yang memeriksa converter dan model contoh di aplikasi user
         ├─ json_converters_test.dart        # menguji konversi DateTime epoch, Uri, dan Duration ke dan dari JSON
         └─ example_model_test.dart          # menguji round trip JSON pada model contoh
```

