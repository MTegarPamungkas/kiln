## Extension: platform

Empat extension yang membungkus kemampuan perangkat. Hampir semuanya punya
`*_gateway.dart`: plugin platform sulit dites, jadi logika (pemetaan status,
stream, penjadwalan) dipisah dari panggilan plugin dan dites dengan fake.

`permission` adalah yang paling banyak menyentuh file native (manifest
Android, plist iOS, flag Podfile), jadi ia mendapat prompt `kinds` supaya hanya
izin yang dipilih yang ditambahkan ke proyek.

### permission

```text
extensions/permission/
├─ extension.yaml                           # manifest: provides: permission · category: platform · exclusive · prompts: kinds (multi-pilih) · patch per kind: android, plist, podfile PERMISSION_*
├─ README.md                                # pengantar extension permission: fungsi, cara pasang, dan contoh pakai
├─ CHANGELOG.md                             # catatan perubahan extension permission per versi
├─ docs/                                    # dokumentasi extension permission untuk pengguna dan kontributor
│  ├─ permissions.md                        # daftar kind izin yang didukung beserta patch native-nya
│  ├─ permission-flow.md                    # menjelaskan alur izin: status, rationale, request, buka settings
│  └─ store-review-notes.md                 # menjelaskan kenapa hanya izin terpilih yang ditambahkan (App Store dan Play)
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason: template yang dirender ke aplikasi user
   ├─ brick.yaml                            # metadata brick Mason: nama, versi, dan variabel template
   └─ __brick__/                            # isi template yang dirender ke proyek aplikasi
      ├─ lib/extensions/permission/                 # kode extension permission yang dirender ke lib aplikasi
      │  ├─ permission_module.dart                  # mendaftarkan implementasi Permissions ke Registry
      │  ├─ device_permissions.dart                 # implementasi kontrak Permissions di atas PermissionGateway
      │  ├─ permission_config.dart                  # konfigurasi bertipe: kind yang aktif, teks rationale bawaan
      │  ├─ permission_gateway.dart                 # membungkus permission_handler (SdkPermissionGateway) agar bisa di-fake di test
      │  ├─ permission_failure_mapper.dart          # mengubah error plugin menjadi Failure(permission atau unavailable)
      │  ├─ permission_kind_guard.dart              # menolak kind yang tidak diaktifkan dengan Failure(configuration), bukan crash native
      │  ├─ permission_flow.dart                    # menjalankan ensure(kind): status, rationale, request, ke settings bila permanen
      │  ├─ permission_group.dart                   # meminta beberapa kind sekaligus, mis. kamera dan mikrofon untuk video
      │  ├─ permission_status_cache.dart            # mengurangi panggilan platform berulang, cache dibatalkan saat onResume
      │  ├─ permission_resume_observer.dart         # mengecek ulang status setelah user kembali dari settings (Lifecycle)
      │  └─ widgets/                                # widget izin siap pakai: gate dan dialog
      │     ├─ permission_gate.dart                 # menampilkan child hanya bila granted, selain itu fallback
      │     ├─ permission_rationale_dialog.dart     # dialog yang menjelaskan alasan izin sebelum permintaan sistem muncul
      │     └─ open_settings_dialog.dart            # dialog yang mengarahkan user ke settings saat izin ditolak permanen
      └─ test/extensions/permission/                # test yang ikut dirender ke aplikasi dan jalan di sana
         ├─ device_permissions_test.dart            # menguji bahwa DevicePermissions meneruskan status dan permintaan ke gateway fake
         ├─ permission_module_test.dart             # menguji bahwa module mendaftarkan Permissions ke Registry
         ├─ permission_config_test.dart             # menguji nilai bawaan kind aktif dan teks rationale
         ├─ permission_failure_mapper_test.dart     # menguji pemetaan error plugin ke Failure permission atau unavailable
         ├─ permission_kind_guard_test.dart         # menguji bahwa kind nonaktif menghasilkan Failure(configuration)
         ├─ permission_flow_test.dart               # menguji alur ensure: status, rationale, request, dan arahan ke settings
         ├─ permission_group_test.dart              # menguji permintaan beberapa kind sekaligus dan penggabungan hasilnya
         ├─ permission_status_cache_test.dart       # menguji bahwa status di-cache dan dibatalkan saat onResume
         ├─ permission_resume_observer_test.dart    # menguji pengecekan ulang status setelah user kembali dari settings
         ├─ permission_gate_test.dart               # menguji bahwa PermissionGate menampilkan child hanya bila granted
         ├─ permission_dialogs_test.dart            # menguji teks dan aksi dialog rationale serta dialog buka settings
         └─ permissions_contract_test.dart          # menjalankan suite kontrak Permissions dari kiln_testing ke implementasi ini
```

### connectivity

```text
extensions/connectivity/
├─ extension.yaml                           # manifest: provides: connectivity · category: connectivity · exclusive · prompts: probe_url (opsional), probe_interval
├─ README.md                                # pengantar extension connectivity: fungsi, cara pasang, dan contoh pakai
├─ CHANGELOG.md                             # catatan perubahan extension connectivity per versi
├─ docs/                                    # dokumentasi extension connectivity untuk pengguna dan kontributor
│  ├─ connectivity.md                       # panduan memakai NetworkMonitor, konfigurasi, dan widget status jaringan
│  └─ offline-handling.md                   # menjelaskan beda online di jaringan dan server terjangkau; kapan memakai probe
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason: template yang dirender ke aplikasi user
   ├─ brick.yaml                            # metadata brick Mason: nama, versi, dan variabel template
   └─ __brick__/                            # isi template yang dirender ke proyek aplikasi
      ├─ lib/extensions/connectivity/               # kode extension connectivity yang dirender ke lib aplikasi
      │  ├─ connectivity_module.dart                # mendaftarkan NetworkMonitor ke Registry
      │  ├─ device_network_monitor.dart             # implementasi kontrak NetworkMonitor di atas ConnectivityGateway
      │  ├─ connectivity_config.dart                # konfigurasi bertipe: URL probe, interval, timeout, jendela debounce
      │  ├─ connectivity_gateway.dart               # membungkus connectivity_plus (SdkConnectivityGateway) agar bisa di-fake di test
      │  ├─ connectivity_failure_mapper.dart        # mengubah error plugin menjadi Failure(unavailable)
      │  ├─ reachability_probe.dart                 # mengirim HEAD ke URL probe lewat kontrak HttpClient (readOrNull), opsional
      │  ├─ status_stabilizer.dart                  # meredam Wi-Fi yang naik turun, memakai Debouncer dari kiln_core
      │  ├─ reconnect_trigger.dart                  # menjalankan aksi tertunda saat status berubah ke online
      │  ├─ offline_guard_middleware.dart           # middleware http.interceptors (when: http_pipeline), gagal cepat Failure(network) saat offline
      │  └─ widgets/                                # widget siap pakai untuk menampilkan status jaringan
      │     ├─ offline_banner.dart                  # menampilkan spanduk saat offline, tidak muncul selama status masih unknown
      │     └─ network_status_builder.dart          # membangun widget sesuai NetworkStatus terkini
      └─ test/extensions/connectivity/              # test yang ikut dirender ke aplikasi dan jalan di sana
         ├─ device_network_monitor_test.dart        # menguji bahwa status dan stream NetworkMonitor mengikuti gateway fake
         ├─ connectivity_module_test.dart           # menguji bahwa module mendaftarkan NetworkMonitor ke Registry
         ├─ connectivity_config_test.dart           # menguji nilai bawaan URL probe, interval, timeout, dan jendela debounce
         ├─ connectivity_failure_mapper_test.dart   # menguji pemetaan error plugin menjadi Failure(unavailable)
         ├─ reachability_probe_test.dart            # menguji probe HEAD: sukses, gagal, dan dilewati bila HttpClient tidak ada
         ├─ status_stabilizer_test.dart             # menguji bahwa Wi-Fi yang naik turun diredam sesuai jendela debounce
         ├─ reconnect_trigger_test.dart             # menguji bahwa aksi tertunda jalan saat status berubah ke online
         ├─ offline_guard_middleware_test.dart      # menguji bahwa request gagal cepat dengan Failure(network) saat offline
         ├─ offline_banner_test.dart                # menguji spanduk muncul saat offline dan tersembunyi saat status unknown
         ├─ network_status_builder_test.dart        # menguji bahwa builder dipanggil sesuai NetworkStatus
         └─ connectivity_contract_test.dart         # menjalankan suite kontrak NetworkMonitor dari kiln_testing ke implementasi ini
```

### notifications

```text
extensions/notifications/
├─ extension.yaml                           # manifest: provides: notifications · category: notifications · exclusive · prompts: default_channel, small_icon, exact_alarms · platform: android, ios
├─ README.md                                # pengantar extension notifications: fungsi, cara pasang, dan contoh pakai
├─ CHANGELOG.md                             # catatan perubahan extension notifications per versi
├─ docs/                                    # dokumentasi extension notifications untuk pengguna dan kontributor
│  ├─ notifications.md                      # panduan memakai Notifications: izin, channel, penjadwalan, dan tap
│  ├─ android-channels.md                   # cara mendefinisikan dan memakai channel notifikasi Android
│  ├─ scheduling-and-timezones.md           # menjelaskan zona waktu perangkat, DST, dan batas penjadwalan
│  └─ troubleshooting-delivery.md           # panduan masalah pengiriman: optimasi baterai Android, delegate iOS, batas web
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason: template yang dirender ke aplikasi user
   ├─ brick.yaml                            # metadata brick Mason: nama, versi, dan variabel template
   └─ __brick__/                            # isi template yang dirender ke proyek aplikasi
      ├─ lib/extensions/notifications/              # kode extension notifications yang dirender ke lib aplikasi
      │  ├─ notifications_module.dart               # mendaftarkan implementasi Notifications ke Registry
      │  ├─ device_notifications.dart               # implementasi kontrak Notifications di atas NotificationGateway
      │  ├─ notification_gateway.dart               # interface yang membungkus plugin notifikasi agar bisa di-fake di test
      │  ├─ plugin_notification_gateway.dart        # implementasi gateway yang memanggil plugin notifikasi di perangkat
      │  ├─ notifications_config.dart               # konfigurasi bertipe: channel bawaan, ikon kecil, suara, kebijakan alarm eksak
      │  ├─ notification_failure_mapper.dart        # mengubah error plugin menjadi Failure(notifications, permission, atau unavailable)
      │  ├─ notification_channels.dart              # mendefinisikan channel Android yang dibuat saat start
      │  ├─ timezone_resolver.dart                  # menentukan tz.local dari zona perangkat, bukan UTC
      │  ├─ notification_payload.dart               # menyandikan payload JSON bertipe (route, argumen) dengan batas ukuran
      │  ├─ notification_id_allocator.dart          # membuat id stabil dari kunci string, mencegah tabrakan id
      │  ├─ notification_tap_hub.dart               # menggabungkan tap foreground, tap latar belakang, dan launchTap
      │  ├─ background_tap_handler.dart             # menerima tap di latar belakang lewat fungsi top-level @pragma('vm:entry-point')
      │  ├─ notification_permission_flow.dart       # meminta izin pada momen yang tepat lewat kontrak Permissions (readOrNull)
      │  └─ reminder_scheduler.dart                 # menjadwalkan ulang pengingat secara idempoten per kunci, aman dipanggil setiap start
      └─ test/extensions/notifications/             # test yang ikut dirender ke aplikasi dan jalan di sana
         ├─ device_notifications_test.dart          # menguji bahwa DeviceNotifications meneruskan perintah ke gateway fake
         ├─ notifications_module_test.dart          # menguji bahwa module mendaftarkan Notifications ke Registry
         ├─ notifications_config_test.dart          # menguji nilai bawaan channel, ikon kecil, suara, dan kebijakan alarm eksak
         ├─ notification_failure_mapper_test.dart   # menguji pemetaan error plugin ke Failure notifications, permission, atau unavailable
         ├─ notification_channels_test.dart         # menguji bahwa channel Android didefinisikan saat start
         ├─ timezone_resolver_test.dart             # menguji bahwa tz.local mengikuti zona perangkat, bukan UTC
         ├─ notification_payload_test.dart          # menguji payload JSON bertipe: round-trip route dan argumen, serta batas ukuran
         ├─ notification_id_allocator_test.dart     # menguji bahwa id stabil per kunci string dan tidak bertabrakan
         ├─ notification_tap_hub_test.dart          # menguji bahwa tap foreground, latar belakang, dan launchTap digabung
         ├─ notification_permission_flow_test.dart  # menguji permintaan izin lewat Permissions, termasuk saat kontrak tidak terdaftar
         ├─ reminder_scheduler_test.dart            # menguji bahwa penjadwalan ulang idempoten per kunci
         └─ notifications_contract_test.dart        # menjalankan suite kontrak Notifications dari kiln_testing ke implementasi ini
```

### image_picker

```text
extensions/image_picker/
├─ extension.yaml                           # manifest: provides: media · category: media · exclusive · prompts: max_bytes, allowed_types · ios: plist · macos: device.camera
├─ README.md                                # pengantar extension image_picker: fungsi, cara pasang, dan contoh pakai
├─ CHANGELOG.md                             # catatan perubahan extension image_picker per versi
├─ docs/                                    # dokumentasi extension image_picker untuk pengguna dan kontributor
│  ├─ image-picker.md                       # panduan memakai MediaPicker untuk memilih gambar dari kamera dan galeri
│  ├─ upload-flow.md                        # menjelaskan alur dari PickedImage ke FileStorage tanpa mengimpor backend
│  └─ platform-notes.md                     # catatan platform: activity dihancurkan di Android, HEIC di iOS, batas web
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason: template yang dirender ke aplikasi user
   ├─ brick.yaml                            # metadata brick Mason: nama, versi, dan variabel template
   └─ __brick__/                            # isi template yang dirender ke proyek aplikasi
      ├─ lib/extensions/image_picker/               # kode extension image_picker yang dirender ke lib aplikasi
      │  ├─ image_picker_module.dart                # mendaftarkan implementasi MediaPicker ke Registry
      │  ├─ device_media_picker.dart                # implementasi kontrak MediaPicker di atas ImagePickerGateway
      │  ├─ image_picker_gateway.dart               # membungkus plugin image_picker agar bisa di-fake di test
      │  ├─ media_picker_config.dart                # konfigurasi bertipe: dimensi dan kualitas bawaan, ukuran maksimum, tipe yang boleh
      │  ├─ media_failure_mapper.dart               # mengubah error PlatformException menjadi Failure(permission, unavailable, atau cancelled)
      │  ├─ mime_sniffer.dart                       # mendeteksi jpeg, png, webp, heic, gif dari byte awal, bukan mimeType plugin
      │  ├─ image_validator.dart                    # memvalidasi ukuran dan tipe gambar, gagal menjadi Failure(validation)
      │  ├─ camera_permission_precheck.dart         # mengecek kontrak Permissions dulu (readOrNull) supaya penolakan jelas
      │  ├─ lost_data_recovery.dart                 # memulihkan hasil pilihan saat activity Android dihancurkan
      │  ├─ picked_image_x.dart                     # tambahan pada PickedImage: toImageProvider dan ukuran terbaca ("1,2 MB")
      │  ├─ picked_image_upload_adapter.dart        # mengubah PickedImage menjadi masukan FileStorage, keduanya tipe dari kiln_core
      │  └─ widgets/                                # widget siap pakai untuk memilih gambar
      │     ├─ image_source_sheet.dart              # bottom sheet untuk memilih sumber gambar, kamera atau galeri
      │     └─ avatar_picker.dart                   # avatar bulat yang bisa diganti, menampilkan Failure dengan ramah
      └─ test/extensions/image_picker/              # test yang ikut dirender ke aplikasi dan jalan di sana
         ├─ device_media_picker_test.dart           # menguji bahwa pilihan gambar dari gateway fake menjadi hasil MediaPicker
         ├─ image_picker_module_test.dart           # menguji bahwa module mendaftarkan MediaPicker ke Registry
         ├─ media_picker_config_test.dart           # menguji nilai bawaan dimensi, kualitas, ukuran maksimum, dan tipe
         ├─ media_failure_mapper_test.dart          # menguji pemetaan PlatformException ke Failure permission, unavailable, atau cancelled
         ├─ mime_sniffer_test.dart                  # menguji deteksi tipe dari byte awal: jpeg, png, webp, heic, gif
         ├─ image_validator_test.dart               # menguji bahwa ukuran atau tipe tidak valid menjadi Failure(validation)
         ├─ camera_permission_precheck_test.dart    # menguji pengecekan izin kamera lewat Permissions sebelum membuka kamera
         ├─ lost_data_recovery_test.dart            # menguji pemulihan hasil pilihan setelah activity Android dihancurkan
         ├─ picked_image_x_test.dart                # menguji toImageProvider dan format ukuran terbaca ("1,2 MB")
         ├─ picked_image_upload_adapter_test.dart   # menguji bahwa PickedImage diubah menjadi masukan FileStorage yang benar
         ├─ image_source_sheet_test.dart            # menguji bottom sheet memilih sumber kamera atau galeri
         ├─ avatar_picker_test.dart                 # menguji bahwa avatar berganti setelah memilih dan Failure tampil ramah
         └─ media_picker_contract_test.dart         # menjalankan suite kontrak MediaPicker dari kiln_testing ke implementasi ini
```

