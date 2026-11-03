# Keystore dan Keychain

- Data Keychain iOS dapat bertahan setelah aplikasi dihapus. `FirstRunWipe`
  membersihkan sisa instalasi lama pada start pertama.
- Android Keystore dapat kehilangan kunci setelah restore atau perubahan
  kredensial perangkat; aplikasi harus siap menerima `Failure`.
- Web memakai IndexedDB terenkripsi dan tidak sekuat Keychain/Keystore native.
- `android.allow_backup=false` mencegah data terenkripsi ikut backup.
