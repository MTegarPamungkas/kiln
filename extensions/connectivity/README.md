# connectivity

Memantau status jaringan dan menyediakan `offline_guard` untuk HTTP.

- `NetworkMonitor` dari `kiln_core` diimplementasikan di atas
  `connectivity_plus`.
- Status distabilkan dengan `Debouncer` agar Wi-Fi yang naik turun tidak
  memicu perubahan berlebihan.
- `ReconnectTrigger` menjalankan aksi tertunda saat kembali online.
- `OfflineGuardMiddleware` (priority 5) menghentikan request saat offline.
- `OfflineBanner` dan `NetworkStatusBuilder` siap dipakai di UI.
- `ReachabilityProbe` opsional memakai `HttpClient` untuk mengecek server.
