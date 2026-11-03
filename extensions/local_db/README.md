# local_db

Implementasi `LocalDatabase` dari `kiln_core` di atas Sembast.

Fitur:

- koleksi dokumen key-value,
- query `where`, `orderBy`, `limit`, dan `offset`,
- stream perubahan koleksi,
- transaksi atomik,
- typed collection dengan `fromJson`/`toJson`,
- backup ekspor/impor JSON,
- antrean sinkronisasi untuk RemoteDatabase,
- migrasi skema,
- enkripsi AES-GCM opsional dengan kunci dari SecureStorage.
