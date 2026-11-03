# Security

## Melaporkan kerentanan

Jangan membuka issue publik untuk kerentanan. Hubungi maintainer repo secara
privat dan sertakan:

- versi Kiln dan extension,
- langkah reproduksi,
- dampak dan permukaan serangan,
- saran perbaikan bila ada.

## Model kepercayaan

- Extension `official`/`verified` boleh memakai hook; tier komunitas memerlukan
  persetujuan eksplisit.
- `kiln_store` memverifikasi SHA-256 arsip dan menolak path traversal.
- `kiln add` berjalan dalam transaksi dengan snapshot dan rollback.
- File yang diedit pengguna tidak dihapus otomatis.

## Rahasia

- Prompt `secret` tidak ditulis ke `kiln.yaml`.
- Jangan menyimpan kunci server di aplikasi klien. `--dart-define` dapat
  diekstrak dari binary.
- Logger, analytics, dan crash reporter memakai `PiiRedactor` dan
  `ConsentController`.

## Dependency

Ikuti `flutter pub outdated` dan review Dependabot. Jangan menambahkan
dependency baru tanpa kebutuhan yang jelas.
