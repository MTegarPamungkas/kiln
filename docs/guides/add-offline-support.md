# Menambahkan dukungan offline

Kombinasi yang direncanakan:

- `connectivity` — memantau jaringan dan menyediakan `offline_guard` middleware.
- `http_cache` — menyajikan respons segar dari cache.
- `local_db` — menyimpan dokumen lokal dan antrean sinkronisasi.

## Pola

1. Baca dari `LocalDatabase` terlebih dahulu.
2. Tampilkan status dari `NetworkMonitor`.
3. Saat online, sinkronkan `sync_queue` ke `RemoteDatabase`.
4. Gunakan `http.interceptors` untuk offline guard, retry, dan cache.
5. Tulis test dengan fake `NetworkMonitor`, `HttpClient`, dan `LocalDatabase`
   dari `kiln_testing`.

`storage`, `http_cache`, dan `local_db` sudah tersedia di katalog.
`connectivity` menyusul pada kelompok platform; lihat
[roadmap](../roadmap.md).
