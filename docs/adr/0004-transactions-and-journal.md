# 0004 — Perubahan diterapkan lewat transaksi dengan jurnal

## Keputusan

`add` dan `remove` menulis perubahan di dalam `Transaction` dengan snapshot di
`.kiln/backups` dan jurnal di `.kiln/journal`. Commit memindahkan jurnal ke
riwayat backup; `kiln rollback` memulihkan transaksi terhenti atau terakhir.

## Alasan

Instalasi menyentuh banyak file: render, pubspec, patch native, codegen, dan
lockfile. Kegagalan di tengah jalan harus bisa dibalik.

## Konsekuensi

- File baru dihapus saat rollback; file lama dipulihkan dari snapshot.
- `doctor` melaporkan jurnal yang masih berjalan.
- Backup dibersihkan saat rollback, tetapi dipertahankan setelah commit untuk
  rollback berikutnya.
