## Extension: storage dan data

Tiga extension penyimpanan lokal, dari yang paling sederhana (key-value) sampai
yang terenkripsi dan yang berbentuk dokumen. Ketiganya tidak saling mengimpor:
`http_cache` dan `rest_auth` memakai `Storage` dan `SecureStorage` lewat
kontrak di `kiln_core`.

### storage

```text
extensions/storage/
├─ extension.yaml  # manifest: provides: storage · category: storage
├─ README.md  # ikhtisar extension: fungsi, cara memasang, dan contoh pemakaian
├─ CHANGELOG.md  # riwayat perubahan extension per versi
├─ docs/  # dokumentasi pemakaian storage dan migrasi key
│  ├─ key-value-storage.md  # panduan membaca dan menulis nilai lewat Prefs dan Storage
│  └─ typed-keys-and-migration.md  # cara memberi nama key dan memigrasi nilai lama
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/  # Mason brick yang dirender menjadi kode extension di aplikasi user
   ├─ brick.yaml  # metadata brick Mason: nama, versi, dan variabel
   └─ __brick__/  # template file yang dirender ke folder aplikasi user
      ├─ lib/extensions/storage/  # kode sumber extension storage yang dirender ke aplikasi user
      │  ├─ prefs.dart  # fasad statis Prefs.read, write, delete, bernama Prefs agar tidak bentrok dengan Storage
      │  ├─ storage_module.dart  # mendaftarkan Storage berbasis SharedPreferences ke Registry
      │  ├─ shared_preferences_storage.dart  # mengimplementasikan Storage key-value di atas shared_preferences
      │  ├─ storage_config.dart  # konfigurasi bertipe: prefix key per app dan flavor
      │  ├─ storage_failure_mapper.dart  # mengubah error plugin dan cast salah menjadi Failure(storage)
      │  ├─ storage_gateway.dart  # membungkus SharedPreferencesAsync agar bisa di-fake di test
      │  ├─ typed_key.dart  # mendefinisikan StorageKey<T> dengan nama, tipe, default, dan serializer
      │  ├─ json_codec.dart  # menyimpan objek lewat jsonEncode dan jsonDecode
      │  ├─ namespaced_storage.dart  # membungkus Storage dengan prefix, dipakai http_cache tanpa menimpa key lain
      │  ├─ ttl_storage.dart  # menyimpan nilai dengan kedaluwarsa, memakai Clock dari kiln_core
      │  └─ storage_migrator.dart  # mengelola versi skema key dan menjalankan langkah migrasi saat start
      └─ test/extensions/storage/  # test extension storage yang dirender ke aplikasi user
         ├─ shared_preferences_storage_test.dart  # menguji bahwa nilai tersimpan, terbaca, dan terhapus lewat gateway palsu
         ├─ storage_module_test.dart  # menguji bahwa module mendaftarkan Storage ke Registry
         ├─ storage_failure_mapper_test.dart  # menguji pemetaan error plugin dan cast salah menjadi Failure(storage)
         ├─ typed_key_test.dart  # menguji nilai default dan serializer pada StorageKey<T>
         ├─ json_codec_test.dart  # menguji bahwa objek tersimpan dan terbaca kembali lewat JSON
         ├─ namespaced_storage_test.dart  # menguji bahwa prefix memisahkan key dan tidak menimpa key lain
         ├─ ttl_storage_test.dart  # menguji bahwa nilai kedaluwarsa sesuai Clock yang dikendalikan test
         ├─ storage_migrator_test.dart  # menguji bahwa langkah migrasi dijalankan saat versi skema key lebih lama
         └─ storage_contract_test.dart  # menjalankan suite kontrak Storage dari kiln_testing ke implementasi ini
```

### secure_storage

```text
extensions/secure_storage/
├─ extension.yaml  # manifest: provides: secure_storage · ios: keychain_sharing · android: allowBackup=false
├─ README.md  # ikhtisar extension: fungsi, cara memasang, dan contoh pemakaian
├─ CHANGELOG.md  # riwayat perubahan extension per versi
├─ docs/  # dokumentasi penyimpanan aman dan perbedaan platform
│  ├─ secure-storage.md  # panduan menyimpan rahasia lewat Vault dan SecureStorage
│  └─ keystore-and-keychain-notes.md  # kehilangan data saat reinstall, backup, dan perbedaan platform
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/  # Mason brick yang dirender menjadi kode extension di aplikasi user
   ├─ brick.yaml  # metadata brick Mason: nama, versi, dan variabel
   └─ __brick__/  # template file yang dirender ke folder aplikasi user
      ├─ lib/extensions/secure_storage/  # kode sumber extension secure_storage yang dirender ke aplikasi user
      │  ├─ vault.dart  # fasad statis Vault.read, write, dan delete untuk data rahasia
      │  ├─ secure_storage_module.dart  # mendaftarkan SecureStorage ke Registry
      │  ├─ keystore_secure_storage.dart  # mengimplementasikan SecureStorage di atas Keychain dan Keystore
      │  ├─ secure_storage_config.dart  # konfigurasi bertipe: opsi Android (encrypted prefs), iOS (accessibility), web
      │  ├─ secure_storage_failure_mapper.dart  # mengubah error plugin menjadi Failure(secure_storage)
      │  ├─ secure_storage_gateway.dart  # membungkus FlutterSecureStorage agar bisa di-fake di test
      │  ├─ secure_token_store.dart  # mengimplementasikan TokenProvider dari kiln_core, dipakai rest_auth
      │  ├─ namespaced_secure_storage.dart  # memberi prefix per extension agar readAll dan clear tidak menyentuh milik lain
      │  ├─ first_run_wipe.dart  # menghapus Keychain sisa instalasi lama pada start pertama iOS
      │  └─ secure_storage_health_check.dart  # menjalankan probe tulis-baca-hapus dan melaporkannya ke doctor dan Logger
      └─ test/extensions/secure_storage/  # test extension secure_storage yang dirender ke aplikasi user
         ├─ secure_storage_test.dart  # menguji bahwa rahasia tersimpan, terbaca, dan terhapus lewat gateway palsu
         ├─ secure_storage_module_test.dart  # menguji bahwa module mendaftarkan SecureStorage ke Registry
         ├─ secure_storage_failure_mapper_test.dart  # menguji pemetaan error plugin menjadi Failure(secure_storage)
         ├─ secure_token_store_test.dart  # menguji bahwa token tersimpan dan terbaca lewat TokenProvider
         ├─ namespaced_secure_storage_test.dart  # menguji bahwa readAll dan clear hanya menyentuh key berprefix sendiri
         ├─ first_run_wipe_test.dart  # menguji bahwa Keychain lama dihapus hanya pada start pertama iOS
         ├─ secure_storage_health_check_test.dart  # menguji bahwa probe tulis-baca-hapus melaporkan hasil ke doctor dan Logger
         └─ secure_storage_contract_test.dart  # menjalankan suite kontrak SecureStorage dari kiln_testing ke implementasi ini
```

### local_db

```text
extensions/local_db/
├─ extension.yaml  # manifest: provides: local_db · category: database · exclusive
├─ README.md  # ikhtisar extension: fungsi, cara memasang, dan contoh pemakaian
├─ CHANGELOG.md  # riwayat perubahan extension per versi
├─ docs/  # dokumentasi database lokal, skema, dan pola offline-first
│  ├─ local-database.md  # panduan memakai LocalDatabase, koleksi, dan query
│  ├─ schema-versioning.md  # cara memakai migrasi dokumen
│  └─ offline-first-pattern.md  # pola offline-first, dipakai guides/add-offline-support.md
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/  # Mason brick yang dirender menjadi kode extension di aplikasi user
   ├─ brick.yaml  # metadata brick Mason: nama, versi, dan variabel
   └─ __brick__/  # template file yang dirender ke folder aplikasi user
      ├─ lib/extensions/local_db/  # kode sumber extension local_db yang dirender ke aplikasi user
      │  ├─ local_db_module.dart  # mendaftarkan LocalDatabase ke Registry
      │  ├─ sembast_local_database.dart  # mengimplementasikan LocalDatabase di atas Sembast
      │  ├─ local_database_opener.dart  # membuka database Sembast, memilih varian IO atau web sesuai platform
      │  ├─ local_database_opener_io.dart  # membuka database Sembast berbasis file di Android, iOS, dan desktop
      │  ├─ local_database_opener_web.dart  # membuka database Sembast berbasis IndexedDB di web
      │  ├─ local_db_config.dart  # konfigurasi bertipe: nama file database, versi skema, path override
      │  ├─ local_db_failure_mapper.dart  # mengubah error Sembast menjadi Failure(database)
      │  ├─ collection_watcher.dart  # menyediakan Stream<List<LocalRecord>> yang diperbarui saat koleksi berubah
      │  ├─ transaction_runner.dart  # menjalankan beberapa operasi dalam satu transaksi atomik
      │  ├─ typed_collection.dart  # membuat LocalCollection bertipe dengan fromJson dan toJson
      │  ├─ query_builder.dart  # menyusun where, orderBy, dan limit menjadi LocalQuery
      │  ├─ schema_migrator.dart  # menjalankan langkah migrasi sesuai versi skema saat database dibuka
      │  ├─ database_encryption.dart  # menyediakan enkripsi opsional lewat kodek Sembast, kunci dari SecureStorage bila ada
      │  ├─ backup_export.dart  # mengekspor dan mengimpor seluruh database sebagai JSON
      │  └─ sync_queue.dart  # menampung antrean perubahan lokal untuk disinkronkan ke RemoteDatabase
      └─ test/extensions/local_db/  # test extension local_db yang dirender ke aplikasi user
         ├─ local_database_test.dart  # menguji bahwa LocalDatabase menyimpan, membaca, dan menghapus dokumen
         ├─ local_db_module_test.dart  # menguji bahwa module mendaftarkan LocalDatabase ke Registry
         ├─ local_db_failure_mapper_test.dart  # menguji pemetaan error Sembast menjadi Failure(database)
         ├─ collection_watcher_test.dart  # menguji bahwa stream koleksi memancarkan data baru saat koleksi berubah
         ├─ transaction_runner_test.dart  # menguji bahwa transaksi bersifat atomik dan dibatalkan saat salah satu operasi gagal
         ├─ typed_collection_test.dart  # menguji konversi fromJson dan toJson pada LocalCollection bertipe
         ├─ query_builder_test.dart  # menguji bahwa where, orderBy, dan limit menjadi LocalQuery yang benar
         ├─ schema_migrator_test.dart  # menguji bahwa langkah migrasi berjalan sesuai versi skema saat open
         ├─ database_encryption_test.dart  # menguji bahwa database terenkripsi hanya terbaca dengan kunci yang sama
         ├─ backup_export_test.dart  # menguji bahwa ekspor lalu impor JSON memulihkan seluruh isi database
         ├─ sync_queue_test.dart  # menguji bahwa antrean menyimpan perubahan lokal untuk disinkronkan
         └─ local_database_contract_test.dart  # menjalankan suite kontrak LocalDatabase dari kiln_testing ke implementasi ini
```

