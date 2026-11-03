# secure_storage

Implementasi `SecureStorage` dari `kiln_core` di atas Keychain/Keystore.

Isi brick:

- gateway `FlutterSecureStorage` yang bisa di-fake,
- konfigurasi Android/iOS/Web,
- prefix per namespace,
- `SecureTokenStore` yang memenuhi `TokenProvider`,
- `FirstRunWipe` untuk sisa Keychain iOS,
- `SecureStorageHealthCheck` untuk probe tulis-baca-hapus.

Extension ini mengatur `android.allow_backup=false` agar data terenkripsi tidak
ikut backup lintas instalasi.
