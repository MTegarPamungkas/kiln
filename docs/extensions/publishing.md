# Menerbitkan extension

## Fase fondasi

Gunakan `kiln ext pack` untuk menghasilkan arsip:

```bash
kiln ext pack extensions/dio --output build/dio-0.2.0.tgz
```

Lalu publikasikan arsip secara manual atau lampirkan ke rilis. `kiln ext
publish` belum aktif karena registry dan `kiln_store` masih diparkir.

## Fase registry

Langkah yang direncanakan:

1. Validasi manifest dan render/analyze.
2. Buat arsip `.tgz` dan hitung SHA-256.
3. Tulis metadata versi (url, checksum, requires, compatibility, tier).
4. Perbarui `registry/index.json`.
5. Publish ke registry/mirror yang dikonfigurasi.

Checksum diverifikasi sebelum instalasi; arsip dengan path traversal ditolak.
