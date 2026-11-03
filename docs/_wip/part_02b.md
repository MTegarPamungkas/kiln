## kiln_extension_sdk

SDK adalah mesin di balik `kiln add`: membaca manifest, menghitung rencana,
merender brick, lalu menerapkan perubahan dalam transaksi yang bisa dibalik.
Bagian `installer/` paling besar, dan tiga subfoldernya (`transaction/`,
`ownership/`, `verification/`) membuat `add` dan `remove` aman.

```text
packages/kiln_extension_sdk/
├─ lib/                                                     # kode sumber SDK: manifest, resolver, renderer, installer, migrator
│  ├─ kiln_extension_sdk.dart                               # barrel yang meng-export API publik SDK
│  ├─ testing.dart                                          # ExtensionTestHarness untuk test milik penulis extension
│  └─ src/                                                  # implementasi internal SDK, dipakai lewat barrel
│     ├─ kiln_exception.dart                                # KilnException, exception untuk kegagalan di proses SDK
│     ├─ manifest/                                          # model dan validasi extension.yaml
│     │  ├─ extension_manifest.dart                         # model ExtensionManifest hasil parse extension.yaml
│     │  ├─ platform_setup.dart                             # model blok platform di manifest untuk patch Android, iOS, macOS, dan web
│     │  ├─ slot.dart                                       # model slot yang dibuka sebuah extension di manifest
│     │  ├─ manifest_validator.dart                         # memvalidasi id, semver, siklus requires, dan field platform
│     │  ├─ prompt_spec.dart                                # tipe prompt url, int, enum, secret beserta validasinya
│     │  ├─ compatibility.dart                              # memeriksa rentang versi kiln_core, Dart, Flutter, dan platform
│     │  └─ contribution.dart                               # model contributes ke slot, dengan syarat when berisi capability opsional
│     ├─ resolver/                                          # menghitung rencana instalasi, konflik, dan upgrade
│     │  ├─ extension_resolver.dart                         # menyelesaikan requires dan provides menjadi daftar extension terpasang
│     │  ├─ resolution_plan.dart                            # model rencana hasil resolusi yang diterapkan installer
│     │  ├─ capability_index.dart                           # indeks capability: extension mana menyediakan apa
│     │  ├─ conflict_report.dart                            # menyusun pesan konflik extension yang bisa ditindaklanjuti
│     │  ├─ dependency_graph.dart                           # graf requires untuk perintah kiln graph dan kiln remove
│     │  └─ upgrade_planner.dart                            # merencanakan upgrade extension dari versi terpasang ke versi target
│     ├─ renderer/                                          # merender brick Mason menjadi file di proyek user
│     │  ├─ brick_renderer.dart                             # merender brick Mason ke proyek user dengan variabel template
│     │  ├─ template_vars.dart                              # mengubah jawaban prompt dan kiln.yaml menjadi variabel Mason
│     │  ├─ collision_policy.dart                           # memutuskan skip, overwrite, atau tanya; deteksi file diedit lewat hash
│     │  └─ hook_policy.dart                                # mengizinkan hooks hanya bila brick tepercaya
│     ├─ installer/                                         # menerapkan extension ke proyek: transaksi, kepemilikan, patch native, verifikasi
│     │  ├─ extension_installer.dart                        # mengorkestrasi add dan remove extension di dalam transaksi
│     │  ├─ extensions_codegen.dart                         # menulis extensions.g.dart di proyek user agar sinkron dengan lockfile
│     │  ├─ lockfile.dart                                   # membaca dan menulis kiln.lock.yaml berisi extension terpasang
│     │  ├─ pubspec_reader.dart                             # membaca dependency dan versi dari pubspec.yaml user
│     │  ├─ pubspec_writer.dart                             # menambah dan menghapus dependency di pubspec.yaml lewat yaml_edit
│     │  ├─ transaction/                                    # transaksi yang bisa dibalik: jurnal, snapshot, dan rollback
│     │  │  ├─ transaction.dart                             # menjalankan langkah instalasi dan mencatatnya ke jurnal
│     │  │  ├─ journal.dart                                 # mencatat langkah yang sudah berjalan sebagai bahan rollback
│     │  │  ├─ snapshot.dart                                # membackup file sebelum diubah ke .kiln/backups
│     │  │  └─ rollback.dart                                # mengembalikan proyek ke kondisi awal dari jurnal dan snapshot
│     │  ├─ ownership/                                      # pelacakan pemilik file hasil render dan patch
│     │  │  ├─ file_ownership.dart                          # mencatat hash tiap file hasil render
│     │  │  └─ patch_journal.dart                           # mencatat pemilik tiap patch dengan reference count
│     │  ├─ native/                                         # patch file native Android, iOS, macOS, dan web di proyek user
│     │  │  ├─ native_setup.dart                            # menerapkan semua patch native sesuai blok platform di manifest
│     │  │  ├─ patch.dart                                   # interface Patch dengan describe, apply, dan revert
│     │  │  ├─ android_gradle.dart                          # mengedit build.gradle Android di proyek user untuk setelan build yang dibutuhkan extension
│     │  │  ├─ android_project.dart                         # mengedit AndroidManifest.xml di proyek user: izin seperti INTERNET dan app links
│     │  │  ├─ ios_app_delegate.dart                        # mengedit AppDelegate iOS di proyek user untuk kode native yang dibutuhkan extension
│     │  │  ├─ ios_entitlements.dart                        # mengedit file entitlements iOS di proyek user, mis. associated domains
│     │  │  ├─ ios_plist.dart                               # menambah kunci Info.plist iOS di proyek user, mis. teks alasan izin
│     │  │  ├─ ios_podfile.dart                             # menambah flag PERMISSION_* di Podfile iOS untuk permission_handler
│     │  │  ├─ macos_entitlements.dart                      # mengedit entitlements macOS di proyek user, mis. network.client dan device.camera
│     │  │  └─ web_index_html.dart                          # mengedit web/index.html di proyek user untuk tag yang dibutuhkan extension
│     │  └─ verification/                                   # pemeriksaan hasil apply dan laporan dry run
│     │     ├─ verifier.dart                                # menjalankan pub get dan dart analyze setelah apply
│     │     └─ dry_run_reporter.dart                        # melaporkan diff yang akan terjadi tanpa menulis file
│     └─ migrator/                                          # migrasi extension antarversi
│        ├─ migration.dart                                  # model Migration: langkah perubahan antarversi extension
│        ├─ migration_actions.dart                          # aksi migrasi: rename_file, delete_file, replace_dependency, update_config, message
│        ├─ migration_loader.dart                           # membaca migrasi dari extensions/<id>/migrations
│        └─ migration_runner.dart                           # menjalankan migrasi berurutan saat upgrade extension
├─ test/                                                    # test unit SDK beserta data uji di fixtures
│  ├─ android_deep_links_test.dart                          # menguji patch AndroidManifest.xml untuk app links dan deep link
│  ├─ android_gradle_test.dart                              # menguji patch build.gradle Android
│  ├─ brick_renderer_test.dart                              # menguji render brick ke folder proyek dengan variabel template
│  ├─ installer_test.dart                                   # menguji alur add dan remove ExtensionInstaller pada proyek contoh
│  ├─ ios_entitlements_test.dart                            # menguji penambahan dan penghapusan kunci entitlements iOS
│  ├─ manifest_test.dart                                    # menguji parsing extension.yaml menjadi ExtensionManifest
│  ├─ resolver_test.dart                                    # menguji resolusi requires, provides, dan exclusive oleh ExtensionResolver
│  ├─ transaction_test.dart                                 # menguji bahwa Transaction menjalankan langkah dan mencatat jurnal
│  ├─ rollback_test.dart                                    # menguji bahwa rollback mengembalikan proyek setelah langkah gagal
│  ├─ snapshot_test.dart                                    # menguji backup file ke .kiln/backups dan pemulihannya
│  ├─ file_ownership_test.dart                              # menguji pencatatan hash file hasil render
│  ├─ patch_journal_test.dart                               # menguji reference count patch yang dimiliki beberapa extension
│  ├─ pubspec_writer_test.dart                              # menguji penambahan dan penghapusan dependency lewat yaml_edit
│  ├─ ios_podfile_test.dart                                 # menguji penambahan flag PERMISSION_* di Podfile iOS
│  ├─ macos_entitlements_test.dart                          # menguji patch entitlements macOS
│  ├─ web_index_html_test.dart                              # menguji patch web/index.html
│  ├─ manifest_validator_test.dart                          # menguji validasi id, semver, siklus requires, dan field platform
│  ├─ prompt_spec_test.dart                                 # menguji tipe prompt url, int, enum, secret beserta validasinya
│  ├─ compatibility_test.dart                               # menguji pemeriksaan rentang versi kiln_core, Dart, Flutter, dan platform
│  ├─ contribution_test.dart                                # menguji contributes ke slot dengan syarat when berisi capability
│  ├─ capability_index_test.dart                            # menguji indeks capability: extension mana menyediakan apa
│  ├─ conflict_report_test.dart                             # menguji pesan konflik yang bisa ditindaklanjuti
│  ├─ dependency_graph_test.dart                            # menguji graf requires untuk kiln graph dan kiln remove
│  ├─ upgrade_planner_test.dart                             # menguji rencana upgrade extension antarversi
│  ├─ collision_policy_test.dart                            # menguji keputusan skip, overwrite, dan tanya saat file bentrok
│  ├─ hook_policy_test.dart                                 # menguji bahwa hooks hanya jalan pada brick tepercaya
│  ├─ template_vars_test.dart                               # menguji pembentukan variabel Mason dari prompt dan kiln.yaml
│  ├─ verifier_test.dart                                    # menguji verifikasi pub get dan dart analyze setelah apply
│  ├─ dry_run_reporter_test.dart                            # menguji laporan diff dry run tanpa menulis file
│  ├─ migration_runner_test.dart                            # menguji eksekusi migrasi berurutan oleh MigrationRunner
│  ├─ migration_actions_test.dart                           # menguji aksi migrasi rename_file, delete_file, replace_dependency, update_config
│  └─ fixtures/                                             # data uji: manifest, proyek contoh, dan brick kecil
│     ├─ manifests/                                         # contoh extension.yaml untuk test manifest dan validator
│     │  ├─ valid/                                          # extension.yaml yang harus lolos validasi
│     │  └─ invalid/                                        # extension.yaml cacat yang harus ditolak validator
│     ├─ projects/                                          # proyek Flutter contoh sebagai target instalasi
│     │  ├─ fresh_app/                                      # aplikasi awal tanpa extension, untuk skenario add pertama
│     │  ├─ app_with_dio/                                   # aplikasi dengan dio terpasang, untuk skenario extension yang bergantung pada http_pipeline
│     │  ├─ app_with_edited_files/                          # aplikasi dengan file hasil render yang diedit user, untuk skenario tabrakan file
│     │  └─ app_with_two_owners/                            # aplikasi dengan patch milik dua extension, untuk skenario reference count
│     └─ bricks/                                            # brick Mason kecil untuk test renderer
│        ├─ tiny_brick/                                     # brick minimal untuk skenario render dasar
│        └─ brick_with_hooks/                               # brick dengan hooks, untuk skenario hook_policy dan brick tepercaya
├─ tool/                                                    # skrip pengembangan package SDK
│  └─ generate_schemas.dart                                 # menghasilkan JSON Schema dari model manifest
├─ analysis_options.yaml                                    # aturan lint dan analyzer untuk package ini
├─ CHANGELOG.md                                             # riwayat perubahan package per versi
├─ pubspec.yaml                                             # metadata dan dependensi package SDK
└─ README.md                                                # pengantar SDK dan cara membangun extension
```

