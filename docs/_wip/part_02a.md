## kiln_core

`kiln_core` adalah satu-satunya package yang boleh dikenal kode aplikasi dan
semua extension. Ia memuat kontrak, model error, runtime modul, state sesi, dan
utilitas privasi, tanpa dependensi ke plugin Flutter apa pun.

```text
packages/kiln_core/
├─ lib/                                           # kode sumber package, diekspor lewat barrel kiln_core.dart
│  ├─ kiln_core.dart                              # barrel yang meng-export seluruh API publik package
│  └─ src/                                        # implementasi internal package, tidak diimpor langsung
│     ├─ contracts/                               # kontrak yang dipenuhi extension
│     │  ├─ account_management.dart               # kontrak opsional PasswordRecovery, EmailVerification, ProfileUpdate di samping AuthRepository
│     │  ├─ analytics.dart                        # kontrak Analytics untuk mencatat event pemakaian aplikasi
│     │  ├─ app_flavor.dart                       # AppFlavor: penanda lingkungan build yang sedang berjalan
│     │  ├─ auth.dart                             # kontrak AuthRepository untuk masuk dan keluar akun pengguna
│     │  ├─ connectivity.dart                     # kontrak NetworkMonitor untuk memantau status koneksi jaringan
│     │  ├─ crash_reporter.dart                   # kontrak CrashReporter untuk melaporkan crash dan error
│     │  ├─ deep_links.dart                       # kontrak DeepLinks untuk menerima tautan yang membuka aplikasi
│     │  ├─ env.dart                              # kontrak Env untuk membaca konfigurasi lingkungan
│     │  ├─ file_storage.dart                     # kontrak FileStorage: upload, download, url, dan hapus file di bucket
│     │  ├─ http_client.dart                      # kontrak HttpClient untuk mengirim request HTTP
│     │  ├─ local_db.dart                         # kontrak LocalDatabase untuk data lokal di perangkat
│     │  ├─ logger.dart                           # kontrak AppLogger untuk mencatat log aplikasi
│     │  ├─ media_picker.dart                     # kontrak MediaPicker untuk memilih gambar atau media dari perangkat
│     │  ├─ notifications.dart                    # kontrak Notifications untuk menampilkan dan mengelola notifikasi
│     │  ├─ permissions.dart                      # kontrak Permissions: cek status, minta izin, dan buka pengaturan
│     │  ├─ remote_database.dart                  # kontrak RemoteDatabase: CRUD dokumen, RemoteQuery, dan watch
│     │  ├─ secure_storage.dart                   # kontrak SecureStorage untuk menyimpan data sensitif
│     │  ├─ social_auth.dart                      # kontrak SocialAuth untuk masuk lewat akun penyedia sosial
│     │  └─ storage.dart                          # kontrak Storage untuk penyimpanan key-value
│     ├─ errors/                                  # model error seragam dan hasil operasi bertipe Result
│     │  ├─ failure.dart                          # kelas Failure, model error seragam untuk semua kontrak
│     │  ├─ failure_codes.dart                    # kelas FailureCode: kode stabil, mis. network.timeout dan auth.invalid_credentials
│     │  └─ result.dart                           # tipe Result<T> yang berisi Ok atau Err(Failure)
│     ├─ runtime/                                 # runtime modul: Registry, urutan init, Lifecycle, bootstrap, dan Slot
│     │  ├─ registry.dart                         # kontrak Registry untuk mendaftarkan dan mengambil layanan
│     │  ├─ get_it_registry.dart                  # implementasi Registry berbasis get_it
│     │  ├─ kiln_module.dart                      # kontrak KilnModule: unit yang mendaftarkan layanan ke Registry saat init
│     │  ├─ module_graph.dart                     # menghitung urutan init dari requires dan mendeteksi siklus
│     │  ├─ lifecycle.dart                        # kontrak Lifecycle: onReady, onPause, onResume, dan dispose
│     │  ├─ bootstrap.dart                        # KilnBootstrap.run: init async dengan timeout dan error handler
│     │  └─ slot.dart                             # OrderedSlot<T> untuk http.interceptors dan router.routes
│     ├─ session/                                 # state sesi login: model sesi, controller, dan penyedia token
│     │  ├─ session.dart                          # model AuthSession dengan userId dan expiresAt
│     │  ├─ session_controller.dart               # SessionController: status unknown, authenticated, unauthenticated, plus stream
│     │  └─ token_provider.dart                   # kontrak TokenProvider untuk mengambil dan me-refresh token
│     ├─ privacy/                                 # persetujuan pengguna dan penyamaran data pribadi
│     │  ├─ consent.dart                          # ConsentController untuk persetujuan analytics dan crash report
│     │  └─ pii_redactor.dart                     # PiiRedactor menyamarkan data pribadi untuk logger, analytics, dan crash report
│     └─ util/                                    # Clock yang bisa di-fake, Debouncer, dan Disposable
│        ├─ clock.dart                            # Clock: sumber waktu yang bisa di-fake di test
│        ├─ debouncer.dart                        # Debouncer yang menunda aksi sampai pemanggilan berhenti
│        └─ disposable.dart                       # kontrak Disposable untuk melepas sumber daya
├─ test/                                          # test unit kiln_core: kontrak, error, runtime, sesi, dan privasi
│  ├─ auth_test.dart                              # menguji kontrak AuthRepository dan Failure saat kredensial salah
│  ├─ failure_test.dart                           # menguji konstruksi dan perbandingan nilai Failure
│  ├─ http_client_test.dart                       # menguji kontrak HttpClient dan error jaringan sebagai Failure
│  ├─ registry_test.dart                          # menguji pendaftaran dan pengambilan layanan lewat Registry
│  ├─ runtime_contracts_test.dart                 # menguji kontrak runtime: Registry dan KilnModule bekerja bersama
│  ├─ result_test.dart                            # menguji Result<T> sebagai Ok atau Err(Failure)
│  ├─ failure_codes_test.dart                     # menguji bahwa nilai FailureCode stabil dan unik
│  ├─ module_graph_test.dart                      # menguji urutan init dari requires dan deteksi siklus
│  ├─ slot_test.dart                              # menguji bahwa OrderedSlot<T> menjaga urutan item
│  ├─ lifecycle_test.dart                         # menguji bahwa Lifecycle memanggil onReady, onPause, onResume, dan dispose
│  ├─ bootstrap_test.dart                         # menguji KilnBootstrap.run: init async, timeout, dan error handler
│  ├─ session_controller_test.dart                # menguji transisi status SessionController dan stream-nya
│  ├─ consent_test.dart                           # menguji status persetujuan ConsentController untuk analytics dan crash report
│  ├─ pii_redactor_test.dart                      # menguji bahwa PiiRedactor menyamarkan data pribadi
│  ├─ clock_test.dart                             # menguji bahwa Clock bisa di-fake untuk mengatur waktu
│  └─ debouncer_test.dart                         # menguji bahwa Debouncer hanya menjalankan aksi terakhir
├─ example/                                       # contoh program yang memakai kiln_core
│  └─ main.dart                                   # contoh minimal memakai Registry, KilnModule, dan KilnBootstrap
├─ analysis_options.yaml                          # aturan lint dan analyzer untuk package ini
├─ CHANGELOG.md                                   # riwayat perubahan package per versi
├─ pubspec.yaml                                   # metadata dan dependensi package, tanpa plugin Flutter
└─ README.md                                      # pengantar package dan cara memakai kontraknya
```

