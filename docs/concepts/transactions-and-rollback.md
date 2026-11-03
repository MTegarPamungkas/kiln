# Transaksi dan rollback

Setiap `add`/`remove` berjalan di dalam `Transaction`:

1. Snapshot file yang akan berubah ke `.kiln/backups/<id>/`.
2. Catat operasi ke `.kiln/journal/<id>.json` sebelum file ditulis.
3. Terapkan semua perubahan.
4. Commit: pindahkan jurnal ke folder backup sebagai riwayat.
5. Jika gagal: `rollback()` memulihkan snapshot dan menghapus file baru.

`kiln rollback` membatalkan transaksi terhenti lebih dulu, lalu transaksi
terakhir yang selesai. `kiln doctor` melaporkan jurnal yang masih berjalan
sebagai operasi terhenti.

`.kiln/journal`, `.kiln/backups`, dan `.kiln/logs` di-ignore Git.
