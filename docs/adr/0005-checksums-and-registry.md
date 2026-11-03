# 0005 — Checksum arsip dan registry sebagai sumber extension

## Keputusan

Distribusi extension memakai arsip `.tgz` dengan SHA-256 di registry index.
Checksum diverifikasi sebelum instalasi; arsip diekstrak dengan penolakan path
traversal. Registry menyimpan id, versi, tier, requires, dan compatibility.

## Alasan

Konten extension harus bisa diverifikasi dan dipilih sesuai kompatibilitas
`kiln_core` proyek.

## Konsekuensi

- `kiln_store` menjadi batas kepercayaan antara registry dan installer.
- Mode offline memakai cache lokal.
- Model distribusi final (Git URL, registry terpisah, atau keduanya) masih
  diparkir dan dicatat di roadmap.
