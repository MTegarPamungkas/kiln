# Pola offline-first

1. Baca dari `LocalDatabase` lebih dulu.
2. Tampilkan status `NetworkMonitor`.
3. Saat online, kirim perubahan dari `SyncQueue` ke `RemoteDatabase`.
4. Terapkan hasil server kembali ke lokal.
5. Gunakan `watch` untuk memperbarui UI tanpa polling.

Pastikan konflik punya aturan yang jelas: last-write-wins, versi server, atau
resolusi manual.
