## kiln_store, kiln_testing, kiln_lints

Tiga package yang menutup celah kepercayaan dan kualitas: store mengunduh
extension dengan verifikasi, testing membuktikan setiap implementasi kontrak
bisa saling menggantikan, dan lints menjaga aplikasi tetap bergantung pada
kontrak.

### kiln_store

```text
packages/kiln_store/                          # package untuk mengunduh, memverifikasi, dan menerbitkan extension
├─ lib/                                       # kode publik dan implementasi package kiln_store
│  ├─ kiln_store.dart                         # mengekspor API publik kiln_store
│  └─ src/                                    # implementasi internal klien registry, verifikasi, dan publish
│     ├─ registry_client.dart                 # mengambil index.json registry dari repositori Git
│     ├─ registry_index.dart                  # model index registry beserta daftar versi tiap extension
│     ├─ registry_config.dart                 # konfigurasi bertipe: URL, mirror, dan ref (branch atau tag)
│     ├─ version_resolver.dart                # memilih versi extension yang cocok dengan kiln_core proyek
│     ├─ search_index.dart                    # pencarian extension secara lokal dari cache
│     ├─ checksum_verifier.dart               # memverifikasi sha256 arsip sebelum dipasang
│     ├─ trust_policy.dart                    # menetapkan level official, verified, community dan konfirmasi sebelum hook jalan
│     ├─ archive_packer.dart                  # membuat arsip .tgz dari folder extension
│     ├─ archive_unpacker.dart                # mengekstrak arsip dan menolak path traversal (zip-slip)
│     ├─ publisher.dart                       # memvalidasi extension lalu mempublikasikannya ke registry
│     ├─ local_cache.dart                     # menyimpan index dan arsip unduhan di disk lokal
│     └─ offline_mode.dart                    # memakai cache lokal saat jaringan tidak tersedia
├─ test/                                      # test unit package kiln_store
│  ├─ registry_client_test.dart               # menguji pengambilan index.json dari URL utama dan mirror
│  ├─ registry_index_test.dart                # menguji parsing index registry dan daftar versi extension
│  ├─ version_resolver_test.dart              # menguji pemilihan versi yang kompatibel dengan kiln_core proyek
│  ├─ search_index_test.dart                  # menguji pencarian lokal extension dari cache
│  ├─ checksum_verifier_test.dart             # menguji bahwa arsip dengan sha256 tidak cocok ditolak
│  ├─ trust_policy_test.dart                  # menguji level kepercayaan dan konfirmasi sebelum hook jalan
│  ├─ archive_packer_test.dart                # menguji pembuatan arsip .tgz berisi seluruh file extension
│  ├─ archive_unpacker_test.dart              # menguji bahwa arsip dengan path traversal (zip-slip) ditolak
│  ├─ publisher_test.dart                     # menguji bahwa extension divalidasi sebelum dipublikasikan
│  ├─ local_cache_test.dart                   # menguji penyimpanan dan pembacaan index serta arsip dari cache
│  ├─ offline_mode_test.dart                  # menguji bahwa mode offline hanya memakai cache lokal
│  └─ fixtures/registry/                      # berisi index.json contoh, arsip valid, dan arsip berbahaya dengan path traversal
├─ analysis_options.yaml                      # aturan analyzer dan lint untuk package kiln_store
├─ CHANGELOG.md                               # riwayat perubahan kiln_store per rilis
├─ pubspec.yaml                               # metadata dan dependensi package kiln_store
└─ README.md                                  # panduan pemakaian dan arsitektur kiln_store
```

### kiln_testing

Dipakai sebagai `dev_dependency` di aplikasi hasil generate dan di tiap
extension. Suite `contracts/` dijalankan ke setiap implementasi: Appwrite,
Firebase, Supabase, dan `rest_auth` harus lolos `auth_repository_contract`
yang sama, dan itulah bukti bahwa backend bisa diganti.

```text
packages/kiln_testing/                            # package fake, suite kontrak, dan harness untuk test
├─ lib/                                           # kode publik dan implementasi package kiln_testing
│  ├─ kiln_testing.dart                           # mengekspor fake, suite kontrak, dan harness
│  └─ src/                                        # implementasi internal fake, kontrak, dan harness
│     ├─ fakes/                                   # fake dan implementasi in-memory untuk kontrak kiln_core
│     │  ├─ fake_http_client.dart                 # mensimulasikan HttpClient dengan respons terprogram dan merekam request
│     │  ├─ in_memory_storage.dart                # mensimulasikan Storage key-value yang tersimpan di memori
│     │  ├─ in_memory_secure_storage.dart         # mensimulasikan SecureStorage di memori tanpa keychain asli
│     │  ├─ fake_auth_repository.dart             # mensimulasikan AuthRepository: login, logout, dan sesi tanpa backend
│     │  ├─ fake_account_management.dart          # mensimulasikan AccountManagement: reset password, verifikasi email, ubah profil
│     │  ├─ fake_social_auth.dart                 # mensimulasikan SocialAuth dengan hasil login sosial yang bisa diatur
│     │  ├─ fake_connectivity.dart                # mensimulasikan NetworkMonitor dengan status online atau offline yang bisa diubah
│     │  ├─ fake_permissions.dart                 # mensimulasikan Permissions dengan status izin yang bisa diatur
│     │  ├─ fake_notifications.dart               # mensimulasikan Notifications dan merekam notifikasi yang ditampilkan
│     │  ├─ fake_deep_links.dart                  # mensimulasikan DeepLinks dengan tautan masuk yang dipicu dari test
│     │  ├─ fake_media_picker.dart                # mensimulasikan MediaPicker dengan hasil pilihan media yang ditentukan test
│     │  ├─ fake_local_database.dart              # mensimulasikan LocalDatabase yang menyimpan data di memori
│     │  ├─ fake_remote_database.dart             # mensimulasikan RemoteDatabase di memori tanpa jaringan
│     │  ├─ fake_file_storage.dart                # mensimulasikan FileStorage dengan isi file yang disimpan di memori
│     │  ├─ fake_analytics.dart                   # mensimulasikan Analytics dan merekam event yang dikirim
│     │  ├─ fake_crash_reporter.dart              # mensimulasikan CrashReporter dan merekam error yang dilaporkan
│     │  ├─ fake_env.dart                         # mensimulasikan Env dengan nilai konfigurasi yang diisi dari test
│     │  ├─ fake_clock.dart                       # mensimulasikan Clock dengan waktu yang dimajukan manual
│     │  └─ recording_logger.dart                 # AppLogger yang menyimpan entri log agar bisa diperiksa test
│     ├─ contracts/                               # suite test yang dijalankan ke SETIAP implementasi kontrak
│     │  ├─ http_client_contract.dart             # memeriksa HttpClient: metode, header, body, dan pemetaan error ke Failure
│     │  ├─ storage_contract.dart                 # memeriksa Storage: simpan, baca, hapus, dan key yang tidak ada
│     │  ├─ secure_storage_contract.dart          # memeriksa SecureStorage: nilai tersimpan, terbaca ulang, dan terhapus
│     │  ├─ auth_repository_contract.dart         # memeriksa AuthRepository: login, logout, sesi, dan Failure kredensial salah
│     │  ├─ account_management_contract.dart      # memeriksa AccountManagement: reset password, verifikasi email, ubah profil
│     │  ├─ social_auth_contract.dart             # memeriksa SocialAuth: login sosial berhasil, dibatalkan, dan gagal
│     │  ├─ local_database_contract.dart          # memeriksa LocalDatabase: tulis, baca, ubah, dan hapus data
│     │  ├─ remote_database_contract.dart         # memeriksa RemoteDatabase: tulis, baca, ubah, hapus, dan error jaringan
│     │  ├─ file_storage_contract.dart            # memeriksa FileStorage: unggah, unduh, dan hapus file
│     │  ├─ connectivity_contract.dart            # memeriksa NetworkMonitor: status koneksi dan perubahannya lewat stream
│     │  ├─ permissions_contract.dart             # memeriksa Permissions: status izin dan hasil permintaan izin
│     │  ├─ notifications_contract.dart           # memeriksa Notifications: izin, penerimaan, dan penanganan notifikasi
│     │  ├─ deep_links_contract.dart              # memeriksa DeepLinks: tautan awal dan tautan yang masuk saat app berjalan
│     │  ├─ media_picker_contract.dart            # memeriksa MediaPicker: media terpilih dan pembatalan oleh pengguna
│     │  ├─ analytics_contract.dart               # memeriksa Analytics: pengiriman event dan properti pengguna
│     │  ├─ crash_reporter_contract.dart          # memeriksa CrashReporter: pelaporan error dan konteks tambahan
│     │  └─ logger_contract.dart                  # memeriksa AppLogger: level log dan pesan yang sampai ke sink
│     └─ harness/                                 # perangkat penunjang test: Registry, widget, matcher, async, golden
│        ├─ test_registry.dart                    # membuat Registry siap pakai berisi fake untuk test
│        ├─ pump_app.dart                         # merender widget di test dengan Registry fake dan wrapper aplikasi
│        ├─ matchers.dart                         # matcher isFailure, isOk, dan hasCode untuk Result dan Failure
│        ├─ async_helpers.dart                    # pumpUntil dan expectEmitsInOrder untuk menunggu kondisi dan urutan stream
│        └─ golden_helpers.dart                   # membandingkan tampilan widget dengan file golden
├─ test/                                          # test unit package kiln_testing
│  └─ fakes_satisfy_contracts_test.dart           # menguji bahwa setiap fake lolos suite kontraknya sendiri
├─ analysis_options.yaml                          # aturan analyzer dan lint untuk package kiln_testing
├─ CHANGELOG.md                                   # riwayat perubahan kiln_testing per rilis
├─ pubspec.yaml                                   # metadata dan dependensi package kiln_testing
└─ README.md                                      # panduan memakai fake, suite kontrak, dan harness
```

### kiln_lints

```text
packages/kiln_lints/                      # plugin lint opsional (Fase 6) agar aplikasi tetap memakai kontrak
├─ lib/                                   # kode publik dan implementasi package kiln_lints
│  ├─ kiln_lints.dart                     # titik masuk plugin custom_lint yang mendaftarkan semua aturan
│  └─ src/rules/                          # satu file per aturan lint
│     ├─ no_cross_extension_import.dart   # melarang extension mengimpor extension lain
│     ├─ prefer_contract_over_impl.dart   # memperingatkan kode app yang memakai implementasi seperti DioClient, bukan kontrak
│     ├─ no_plugin_in_features.dart       # melarang folder features/ mengimpor plugin langsung
│     ├─ no_edit_generated_files.dart     # memperingatkan bila extensions.g.dart diubah manual
│     └─ require_failure_handling.dart    # memperingatkan Result yang dipakai tanpa menangani Failure
├─ test/                                  # test unit package kiln_lints
│  └─ rules_test.dart                     # menguji tiap aturan lint terhadap kode yang melanggar dan yang patuh
├─ example/                               # proyek contoh kecil yang sengaja memicu setiap aturan lint
├─ analysis_options.yaml                  # aturan analyzer dan lint untuk package kiln_lints
├─ CHANGELOG.md                           # riwayat perubahan kiln_lints per rilis
├─ pubspec.yaml                           # metadata dan dependensi package kiln_lints
└─ README.md                              # panduan memasang plugin dan daftar aturan lint
```

