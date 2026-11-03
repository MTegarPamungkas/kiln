# 0001 — Kiln tidak pernah mengedit kode milik pengguna

## Keputusan

Kiln hanya memiliki file yang dicatat di lockfile: hasil render extension dan
`lib/extensions/extensions.g.dart`. `kiln remove` menghapus file hanya bila
hash-nya masih sama dengan lockfile. File yang diedit pengguna dilewati kecuali
`--force`.

## Alasan

Pengguna harus bisa memperbaiki dan mengembangkan kode hasil generate tanpa
takut ditimpa. Kepemilikan berbasis hash membuat batas ini eksplisit.

## Konsekuensi

- Tidak ada update yang menimpa edit pengguna secara diam-diam.
- Konflik dilaporkan dan pengguna memilih `--force` atau menyelesaikan manual.
- `kiln doctor` adalah alat utama untuk mendeteksi perubahan.
