### supabase

```text
extensions/supabase/
├─ extension.yaml  # manifest: provides: auth, social_auth, remote_database, file_storage · category: auth · exclusive · prompts: url, anon_key (secret), schema · android: url_schemes
├─ README.md  # pengantar extension, cara pasang, dan contoh pemakaian
├─ CHANGELOG.md  # riwayat perubahan extension per versi
├─ docs/  # dokumentasi extension untuk pengembang aplikasi
│  ├─ supabase-setup.md  # langkah menyiapkan project Supabase dan mengisi url serta anon key
│  ├─ row-level-security.md  # contoh policy untuk tabel yang dipakai RemoteDatabase
│  └─ email-confirmation-and-redirects.md  # callback lewat kontrak DeepLinks bila deep_link terpasang
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/  # template Mason yang merender kode extension ke aplikasi user
   ├─ brick.yaml  # metadata brick Mason: nama, versi, dan variabel template
   └─ __brick__/  # isi template yang dirender ke proyek aplikasi user
      ├─ lib/extensions/supabase/  # kode sumber extension supabase di aplikasi hasil generate
      │  ├─ supabase_module.dart  # mendaftarkan auth, social_auth, remote_database, dan file_storage ke Registry
      │  ├─ supabase_auth_repository.dart  # implementasi AuthRepository lewat Supabase Auth
      │  ├─ supabase_client.dart  # menyiapkan klien Supabase dari url dan anon key
      │  ├─ supabase_gateway.dart  # membungkus supabase_flutter agar bisa di-fake di test
      │  ├─ supabase_failure_mapper.dart  # mengubah error Supabase menjadi Failure
      │  ├─ supabase_config.dart  # konfigurasi bertipe: url, anon key, schema, alur PKCE
      │  ├─ supabase_account_management.dart  # implementasi AccountManagement: reset password, verifikasi email, ubah profil
      │  ├─ supabase_token_provider.dart  # menyediakan TokenProvider dari access token sesi
      │  ├─ supabase_session_bridge.dart  # meneruskan onAuthStateChange ke SessionController
      │  ├─ supabase_link_handler.dart  # menerima callback konfirmasi email lewat DeepLinks (readOrNull)
      │  ├─ postgrest_gateway.dart  # membungkus PostgREST agar bisa di-fake: interface dan SdkPostgrestGateway
      │  ├─ supabase_remote_database.dart  # implementasi RemoteDatabase: CRUD dokumen dan query lewat PostgREST
      │  ├─ supabase_query_mapper.dart  # mengubah RemoteQuery menjadi filter PostgREST
      │  ├─ supabase_realtime_gateway.dart  # membungkus saluran realtime Supabase untuk watch() agar bisa di-fake
      │  ├─ supabase_storage_gateway.dart  # membungkus Supabase Storage agar bisa di-fake: interface dan SdkSupabaseStorageGateway
      │  └─ supabase_file_storage.dart  # implementasi FileStorage dengan signed URL lewat Supabase Storage
      └─ test/extensions/supabase/  # test kode extension supabase di aplikasi hasil generate
         ├─ supabase_auth_test.dart  # menguji alur AuthRepository Supabase dengan gateway yang di-fake
         ├─ supabase_failure_mapper_test.dart  # menguji bahwa error Supabase dipetakan ke Failure dan FailureCode yang tepat
         ├─ supabase_module_test.dart  # menguji bahwa module mendaftarkan semua kontrak ke Registry
         ├─ supabase_config_test.dart  # menguji nilai bawaan konfigurasi url, anon key, schema, dan PKCE
         ├─ supabase_account_management_test.dart  # menguji reset password, verifikasi email, dan ubah profil
         ├─ supabase_token_provider_test.dart  # menguji bahwa token diambil dari access token sesi aktif
         ├─ supabase_session_bridge_test.dart  # menguji bahwa perubahan auth state diteruskan ke SessionController
         ├─ supabase_link_handler_test.dart  # menguji penerimaan callback konfirmasi email lewat DeepLinks
         ├─ supabase_remote_database_test.dart  # menguji CRUD dokumen RemoteDatabase terhadap PostgrestGateway palsu
         ├─ supabase_query_mapper_test.dart  # menguji bahwa RemoteQuery diterjemahkan ke filter PostgREST yang benar
         ├─ supabase_file_storage_test.dart  # menguji upload, download, hapus, dan signed URL pada FileStorage
         └─ supabase_contract_test.dart  # menjalankan suite kontrak auth, social_auth, remote_database, file_storage dari kiln_testing
```

### rest_auth

```text
extensions/rest_auth/
├─ extension.yaml  # manifest: provides: auth · requires: http_client, secure_storage · category: auth · exclusive · prompts: base_url, path login, register, refresh, logout, me
├─ README.md  # pengantar extension, cara pasang, dan contoh pemakaian
├─ CHANGELOG.md  # riwayat perubahan extension per versi
├─ docs/  # dokumentasi extension untuk pengembang aplikasi
│  ├─ rest-auth.md  # panduan memasang rest_auth dan mengisi base_url serta path endpoint
│  ├─ server-contract.md  # bentuk JSON permintaan dan respons login, register, refresh, logout, me
│  └─ token-refresh.md  # alur refresh single-flight dan kapan sesi dianggap berakhir
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/  # template Mason yang merender kode extension ke aplikasi user
   ├─ brick.yaml  # metadata brick Mason: nama, versi, dan variabel template
   └─ __brick__/  # isi template yang dirender ke proyek aplikasi user
      ├─ lib/extensions/rest_auth/  # kode sumber extension rest_auth di aplikasi hasil generate
      │  ├─ rest_auth_module.dart  # mendaftarkan RestAuth sebagai AuthRepository ke Registry
      │  ├─ rest_auth.dart  # implementasi AuthRepository (kelas RestAuth) lewat HttpClient dan endpoint REST
      │  ├─ rest_auth_config.dart  # konfigurasi bertipe: base_url dan path login, register, refresh, logout, me
      │  ├─ rest_auth_failure_mapper.dart  # mengubah status HTTP dan badan error server menjadi Failure
      │  ├─ rest_token_store.dart  # menyimpan access dan refresh token lewat SecureStorage
      │  ├─ token_refresher.dart  # menjalankan refresh single-flight, request paralel menunggu satu hasil
      │  ├─ jwt_expiry.dart  # membaca exp JWT tanpa verifikasi untuk refresh sebelum kedaluwarsa
      │  ├─ auth_response_parser.dart  # mengurai respons auth: camelCase atau snake_case, bentuk token bervariasi
      │  ├─ auth_middleware.dart  # menambahkan header Bearer, contributes: http.interceptors (priority 10)
      │  ├─ unauthorized_handler.dart  # menangani 401: refresh, ulang sekali, bila gagal signOut
      │  ├─ rest_account_management.dart  # implementasi AccountManagement: reset password dan verifikasi email lewat endpoint opsional
      │  └─ rest_session_bridge.dart  # mengisi SessionController dan TokenProvider dari sesi RestAuth
      └─ test/extensions/rest_auth/  # test kode extension rest_auth di aplikasi hasil generate
         ├─ rest_auth_test.dart  # menguji RestAuth sebagai AuthRepository terhadap HttpClient palsu
         ├─ rest_auth_module_test.dart  # menguji bahwa module mendaftarkan AuthRepository ke Registry
         ├─ rest_auth_failure_mapper_test.dart  # menguji pemetaan status HTTP dan badan error ke Failure
         ├─ rest_token_store_test.dart  # menguji penyimpanan, pembacaan, dan penghapusan token di SecureStorage
         ├─ token_refresher_test.dart  # menguji bahwa request paralel berbagi satu refresh single-flight
         ├─ jwt_expiry_test.dart  # menguji pembacaan exp JWT dan batas waktu refresh sebelum kedaluwarsa
         ├─ auth_response_parser_test.dart  # menguji penguraian respons camelCase, snake_case, dan bentuk token bervariasi
         ├─ auth_middleware_test.dart  # menguji bahwa header Bearer ditambahkan ke request
         ├─ unauthorized_handler_test.dart  # menguji bahwa 401 memicu refresh, ulang sekali, dan signOut bila gagal
         ├─ rest_account_management_test.dart  # menguji reset password dan verifikasi email lewat endpoint opsional
         ├─ rest_session_bridge_test.dart  # menguji bahwa SessionController dan TokenProvider terisi dari sesi
         └─ rest_auth_contract_test.dart  # menjalankan suite kontrak auth_repository_contract dari kiln_testing ke implementasi ini
```

### social_login

```text
extensions/social_login/
├─ extension.yaml  # manifest: requires: social_auth · category: social · prompts: google_server_client_id, google_ios_client_id, apple_service_id · ios: apple_sign_in
├─ README.md  # pengantar extension, cara pasang, dan contoh pemakaian
├─ CHANGELOG.md  # riwayat perubahan extension per versi
├─ docs/  # dokumentasi extension untuk pengembang aplikasi
│  ├─ social-login.md  # panduan memasang social_login dan mengisi client id Google dan Apple
│  ├─ google-setup.md  # menyiapkan client id Android, iOS, dan server Google serta SHA-1
│  └─ apple-setup.md  # menyiapkan capability, service id, dan Apple di Android atau web
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/  # template Mason yang merender kode extension ke aplikasi user
   ├─ brick.yaml  # metadata brick Mason: nama, versi, dan variabel template
   └─ __brick__/  # isi template yang dirender ke proyek aplikasi user
      ├─ lib/extensions/social_login/  # kode sumber extension social_login di aplikasi hasil generate
      │  ├─ social_login_module.dart  # mendaftarkan SocialLogin ke Registry
      │  ├─ social_login.dart  # implementasi SocialLogin untuk masuk dengan Google dan Apple
      │  ├─ social_credentials.dart  # mengambil credential dari SDK Google dan Apple lewat gateway
      │  ├─ social_login_failure_mapper.dart  # mengubah error SDK Google dan Apple menjadi Failure
      │  ├─ social_login_config.dart  # konfigurasi bertipe: client id dan provider yang diaktifkan
      │  ├─ nonce_generator.dart  # membuat nonce acak aman dan hash SHA-256 untuk Apple
      │  ├─ social_availability.dart  # menentukan provider sosial yang tersedia di platform yang berjalan
      │  ├─ google_credential_gateway.dart  # membungkus google_sign_in agar bisa di-fake: interface dan SdkGoogleCredentialGateway
      │  ├─ apple_credential_gateway.dart  # membungkus sign_in_with_apple agar bisa di-fake: interface dan SdkAppleCredentialGateway
      │  ├─ social_sign_out_listener.dart  # mengeluarkan sesi Google saat AuthRepository.signOut dipanggil
      │  └─ widgets/  # widget siap pakai untuk login sosial
      │     ├─ social_login_buttons.dart  # tombol Google dan Apple sesuai pedoman merek, mengikuti ketersediaan
      │     └─ social_login_panel.dart  # panel siap pakai dengan state loading dan pesan Failure
      └─ test/extensions/social_login/  # test kode extension social_login di aplikasi hasil generate
         ├─ social_login_test.dart  # menguji alur SocialLogin untuk Google dan Apple dengan gateway yang di-fake
         ├─ social_login_failure_mapper_test.dart  # menguji pemetaan error SDK Google dan Apple ke Failure
         ├─ social_login_module_test.dart  # menguji bahwa module mendaftarkan SocialLogin ke Registry
         ├─ social_login_config_test.dart  # menguji nilai konfigurasi client id dan provider yang diaktifkan
         ├─ nonce_generator_test.dart  # menguji keacakan nonce dan kebenaran hash SHA-256
         ├─ social_availability_test.dart  # menguji provider yang tersedia per platform
         ├─ social_sign_out_listener_test.dart  # menguji bahwa signOut AuthRepository memicu keluar dari Google
         ├─ social_login_buttons_test.dart  # menguji bahwa tombol tampil sesuai ketersediaan provider
         ├─ social_login_panel_test.dart  # menguji state loading dan pesan Failure pada panel
         └─ social_auth_contract_test.dart  # menjalankan suite kontrak social_auth dari kiln_testing ke implementasi ini
```

### biometric

```text
extensions/biometric/
├─ extension.yaml  # manifest: provides: biometric · category: security · android: USE_BIOMETRIC, FlutterFragmentActivity · ios: NSFaceIDUsageDescription · platforms: android, ios, macos (bukan web)
├─ README.md  # pengantar extension, cara pasang, dan contoh pemakaian
├─ CHANGELOG.md  # riwayat perubahan extension per versi
├─ docs/  # dokumentasi extension untuk pengembang aplikasi
│  ├─ biometric.md  # panduan memasang extension biometric dan memakai fasad Biometric
│  ├─ app-lock.md  # cara kerja kunci aplikasi setelah app di latar belakang
│  └─ platform-requirements.md  # persyaratan platform: tema AppCompat Android 8 ke bawah dan batas web
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/  # template Mason yang merender kode extension ke aplikasi user
   ├─ brick.yaml  # metadata brick Mason: nama, versi, dan variabel template
   └─ __brick__/  # isi template yang dirender ke proyek aplikasi user
      ├─ lib/extensions/biometric/  # kode sumber extension biometric di aplikasi hasil generate
      │  ├─ biometric.dart  # fasad Biometric: canAuthenticate, availableBiometrics, dan authenticate
      │  ├─ biometric_module.dart  # mendaftarkan fasad Biometric ke Registry
      │  ├─ biometric_config.dart  # konfigurasi bertipe: alasan bawaan, masa tenggang, biometricOnly
      │  ├─ biometric_failure_mapper.dart  # mengubah error plugin menjadi Failure: tabel kode ke FailureCode beserta pesannya
      │  ├─ biometric_gateway.dart  # membungkus LocalAuthentication agar bisa di-fake: interface dan SdkBiometricGateway
      │  ├─ biometric_availability.dart  # menyatakan status ketersediaan: available, notEnrolled, noHardware, unsupportedPlatform
      │  ├─ biometric_gate.dart  # menjaga aksi lewat guard(action): autentikasi dulu, masa tenggang memakai Clock
      │  ├─ app_lock.dart  # mengunci saat onPause lebih lama dari batas, membuka lewat biometrik
      │  ├─ app_lock_scope.dart  # widget penutup layar saat terkunci, contributes: app.wrappers
      │  └─ biometric_protected_storage.dart  # implementasi SecureStorage yang menuntut autentikasi sebelum read (readOrNull)
      └─ test/extensions/biometric/  # test kode extension biometric di aplikasi hasil generate
         ├─ biometric_test.dart  # menguji fasad Biometric: canAuthenticate, availableBiometrics, dan authenticate
         ├─ biometric_module_test.dart  # menguji bahwa module mendaftarkan Biometric ke Registry
         ├─ biometric_config_test.dart  # menguji nilai bawaan alasan, masa tenggang, dan biometricOnly
         ├─ biometric_failure_mapper_test.dart  # menguji pemetaan kode error plugin ke FailureCode dan pesannya
         ├─ biometric_availability_test.dart  # menguji penentuan status available, notEnrolled, noHardware, unsupportedPlatform
         ├─ biometric_gate_test.dart  # menguji guard: autentikasi dulu dan masa tenggang memakai Clock palsu
         ├─ app_lock_test.dart  # menguji bahwa kunci aktif setelah onPause melewati batas
         ├─ app_lock_scope_test.dart  # menguji bahwa layar tertutup saat terkunci dan terbuka setelah autentikasi
         └─ biometric_protected_storage_test.dart  # menguji bahwa read menuntut autentikasi lebih dulu
```

