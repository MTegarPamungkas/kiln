# Model keamanan

## Trust tier

- `official` — dipelihara tim Kiln.
- `verified` — ditinjau, checksum dan manifest diverifikasi.
- `community` — hook memerlukan persetujuan eksplisit.

## Hook

Hook menjalankan kode di mesin pengguna. `HookPolicy` hanya mengizinkan tier
`official`/`verified` atau persetujuan `--yes`. Pada fase fondasi, hooks tidak
dieksekusi otomatis oleh installer; extension yang memilikinya dilaporkan.

## Checksum dan arsip

`kiln_store` (fase registry) memverifikasi SHA-256 arsip sebelum memasang dan
menolak path traversal saat mengekstrak. Registry index membawa versi, tier,
requires, dan compatibility.

## Rahasia

- Prompt `secret` tidak ditulis ke `kiln.yaml`.
- Nilai build-time dibaca lewat `String.fromEnvironment`.
- Nilai `--dart-define` masih bisa diekstrak dari binary; jangan menyimpan
  kunci server di aplikasi klien.
- Logger, analytics, dan crash reporter memakai `PiiRedactor` dan
  `ConsentController` dari `kiln_core`.

## Rollback

Transaksi menyimpan snapshot sebelum mengubah file dan jurnal untuk rollback,
sehingga kegagalan di tengah proses tidak meninggalkan proyek setengah jadi.
