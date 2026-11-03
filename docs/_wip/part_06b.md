## Extension: backend dan auth

Enam extension untuk identitas dan data jarak jauh. Tiga backend (`appwrite`,
`firebase`, `supabase`) memenuhi tiga kontrak sekaligus: `AuthRepository`,
`RemoteDatabase`, dan `FileStorage`. `rest_auth` memenuhi `AuthRepository`
saja, di atas `http_client`. `social_login` dan `biometric` menambah jalur
masuk tanpa mengubah kontrak auth.

Backend sengaja **tidak** punya fasad statis. Kode aplikasi membaca kontrak dari
Registry, dan aturan lint `prefer_contract_over_impl` menolak impor langsung ke
kelas backend.

Tiap backend memakai pola gateway yang sama, supaya logika sesi dan pemetaan
error bisa dites tanpa akun sungguhan:

```text
kontrak kiln_core  ←  <backend>_auth_repository / _remote_database / _file_storage
                              ↓ memakai
                       <backend>_*_gateway (interface)  ←  Sdk*Gateway (plugin) | Fake (test)
```

### appwrite

```text
extensions/appwrite/
├─ extension.yaml  # manifest: provides: auth, remote_database, file_storage · category: auth · exclusive · prompts: endpoint, project_id, database_id, bucket_id
├─ README.md  # ikhtisar extension: fungsi, cara memasang, dan contoh pemakaian
├─ CHANGELOG.md  # riwayat perubahan extension per versi
├─ docs/  # dokumentasi setup, izin, dan perbedaan perilaku Appwrite
│  ├─ appwrite-setup.md  # buat project, platform, database, dan bucket
│  ├─ collections-and-permissions.md  # izin dokumen dan RemoteQuery yang didukung
│  └─ backend-swap-notes.md  # beda perilaku dibanding firebase dan supabase
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/  # Mason brick yang dirender menjadi kode extension di aplikasi user
   ├─ brick.yaml  # metadata brick Mason: nama, versi, dan variabel
   └─ __brick__/  # template file yang dirender ke folder aplikasi user
      ├─ lib/extensions/appwrite/  # kode sumber extension appwrite yang dirender ke aplikasi user
      │  ├─ appwrite_module.dart  # mendaftarkan AuthRepository, RemoteDatabase, dan FileStorage ke Registry
      │  ├─ appwrite_auth.dart  # mengimplementasikan AuthRepository dengan Account Appwrite
      │  ├─ appwrite_account.dart  # membungkus panggilan layanan Account Appwrite untuk dipakai appwrite_auth
      │  ├─ appwrite_config.dart  # konfigurasi bertipe: endpoint, projectId, databaseId, bucketId
      │  ├─ appwrite_client_factory.dart  # membuat Client dengan setSelfSigned hanya di flavor development
      │  ├─ appwrite_failure_mapper.dart  # mengubah error Appwrite menjadi Failure (401, 404, 409, 429, jaringan)
      │  ├─ appwrite_account_management.dart  # mengimplementasikan AccountManagement: reset password, verifikasi email, ubah profil
      │  ├─ appwrite_session_bridge.dart  # mengisi SessionController dan TokenProvider dari kiln_core
      │  ├─ appwrite_database_gateway.dart  # membungkus Appwrite Databases lewat SdkAppwriteDatabaseGateway agar bisa di-fake di test
      │  ├─ appwrite_remote_database.dart  # mengimplementasikan RemoteDatabase di atas gateway database Appwrite
      │  ├─ appwrite_query_mapper.dart  # mengubah RemoteQuery menjadi Query Appwrite
      │  ├─ appwrite_realtime_gateway.dart  # membungkus langganan Realtime untuk watch() agar bisa di-fake di test
      │  ├─ appwrite_storage_gateway.dart  # membungkus Appwrite Storage lewat SdkAppwriteStorageGateway agar bisa di-fake di test
      │  └─ appwrite_file_storage.dart  # mengimplementasikan FileStorage: upload, download, url, hapus
      └─ test/extensions/appwrite/  # test extension appwrite yang dirender ke aplikasi user
         ├─ appwrite_auth_test.dart  # menguji alur masuk, keluar, dan sesi AuthRepository dengan Account palsu
         ├─ appwrite_module_test.dart  # menguji bahwa module mendaftarkan kontrak Appwrite ke Registry
         ├─ appwrite_config_test.dart  # menguji bahwa konfigurasi terbaca dari endpoint, projectId, databaseId, dan bucketId
         ├─ appwrite_failure_mapper_test.dart  # menguji pemetaan kode 401, 404, 409, 429, dan error jaringan menjadi Failure
         ├─ appwrite_account_management_test.dart  # menguji reset password, verifikasi email, dan ubah profil beserta kegagalannya
         ├─ appwrite_session_bridge_test.dart  # menguji bahwa sesi Appwrite mengisi SessionController dan TokenProvider
         ├─ appwrite_remote_database_test.dart  # menguji operasi RemoteDatabase dengan database gateway palsu
         ├─ appwrite_query_mapper_test.dart  # menguji bahwa RemoteQuery diterjemahkan ke Query Appwrite yang benar
         ├─ appwrite_realtime_gateway_test.dart  # menguji bahwa langganan Realtime ditutup saat dispose
         ├─ appwrite_file_storage_test.dart  # menguji upload, download, url, dan hapus berkas dengan storage gateway palsu
         └─ appwrite_contract_test.dart  # menjalankan suite kontrak auth, remote_database, file_storage dari kiln_testing ke implementasi ini
```

### firebase

```text
extensions/firebase/
├─ extension.yaml  # manifest: provides: auth, social_auth, remote_database, file_storage · category: auth · exclusive · manual_steps: flutterfire configure
├─ README.md  # ikhtisar extension: fungsi, cara memasang, dan contoh pemakaian
├─ CHANGELOG.md  # riwayat perubahan extension per versi
├─ docs/  # dokumentasi setup, emulator, dan aturan keamanan Firebase
│  ├─ firebase-setup.md  # panduan membuat project Firebase dan menyambungkannya ke aplikasi
│  ├─ flutterfire-configure.md  # langkah manual yang dilacak doctor
│  ├─ emulators.md  # flavor development memakai Firebase Emulator Suite
│  └─ security-rules.md  # contoh aturan Firestore dan Storage yang cocok dengan RemoteQuery
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/  # Mason brick yang dirender menjadi kode extension di aplikasi user
   ├─ brick.yaml  # metadata brick Mason: nama, versi, dan variabel
   ├─ hooks/  # hook Mason yang berjalan saat brick di-generate
   │  ├─ pubspec.yaml  # dependensi paket untuk menjalankan hook
   │  └─ pre_gen.dart  # memeriksa flutterfire CLI dan firebase_options.dart, hanya memberi peringatan
   └─ __brick__/  # template file yang dirender ke folder aplikasi user
      ├─ lib/extensions/firebase/  # kode sumber extension firebase yang dirender ke aplikasi user
      │  ├─ firebase_module.dart  # mendaftarkan AuthRepository, SocialAuth, RemoteDatabase, dan FileStorage ke Registry
      │  ├─ firebase_app.dart  # menginisialisasi Firebase sebelum layanan lain dipakai
      │  ├─ firebase_auth_repository.dart  # mengimplementasikan AuthRepository di atas FirebaseAuth lewat gateway
      │  ├─ firebase_gateway.dart  # membungkus FirebaseAuth agar bisa di-fake di test
      │  ├─ firebase_failure_mapper.dart  # mengubah error Firebase menjadi Failure
      │  ├─ firebase_config.dart  # konfigurasi bertipe: sumber options, host emulator, flag emulator
      │  ├─ firebase_emulator.dart  # mengarahkan auth, firestore, dan storage ke emulator di flavor development
      │  ├─ firebase_account_management.dart  # mengimplementasikan AccountManagement: reset password, verifikasi email, ubah profil
      │  ├─ firebase_id_token_provider.dart  # mengimplementasikan TokenProvider dari getIdToken dengan refresh otomatis
      │  ├─ firebase_session_bridge.dart  # meneruskan authStateChanges ke SessionController
      │  ├─ firestore_gateway.dart  # membungkus Firestore lewat SdkFirestoreGateway agar bisa di-fake di test
      │  ├─ firestore_remote_database.dart  # mengimplementasikan RemoteDatabase di atas Firestore
      │  ├─ firestore_query_mapper.dart  # mengubah RemoteQuery menjadi query Firestore, menolak kombinasi tanpa indeks
      │  ├─ firebase_storage_gateway.dart  # membungkus Firebase Storage lewat SdkFirebaseStorageGateway agar bisa di-fake di test
      │  └─ firebase_file_storage.dart  # mengimplementasikan FileStorage dengan progress upload
      └─ test/extensions/firebase/  # test extension firebase yang dirender ke aplikasi user
         ├─ firebase_auth_test.dart  # menguji alur masuk, keluar, dan sesi AuthRepository dengan FirebaseAuth palsu
         ├─ firebase_failure_mapper_test.dart  # menguji pemetaan error Firebase menjadi Failure
         ├─ firebase_module_test.dart  # menguji bahwa module mendaftarkan kontrak Firebase ke Registry
         ├─ firebase_config_test.dart  # menguji bahwa konfigurasi memilih sumber options dan flag emulator
         ├─ firebase_emulator_test.dart  # menguji bahwa auth, firestore, dan storage diarahkan ke emulator di flavor development
         ├─ firebase_account_management_test.dart  # menguji reset password, verifikasi email, dan ubah profil beserta kegagalannya
         ├─ firebase_id_token_provider_test.dart  # menguji bahwa token ID diambil lewat getIdToken dan di-refresh otomatis
         ├─ firebase_session_bridge_test.dart  # menguji bahwa perubahan authStateChanges memperbarui SessionController
         ├─ firestore_remote_database_test.dart  # menguji operasi RemoteDatabase dengan Firestore gateway palsu
         ├─ firestore_query_mapper_test.dart  # menguji bahwa RemoteQuery menjadi query Firestore dan kombinasi tanpa indeks ditolak
         ├─ firebase_file_storage_test.dart  # menguji operasi FileStorage dan progress upload dengan storage gateway palsu
         └─ firebase_contract_test.dart  # menjalankan suite kontrak auth, social_auth, remote_database, file_storage dari kiln_testing ke implementasi ini
```

