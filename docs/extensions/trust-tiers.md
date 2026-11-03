# Trust tier

| Tier | Arti | Hook |
| --- | --- | --- |
| `official` | Dipelihara tim Kiln | Diizinkan |
| `verified` | Ditinjau dan checksum diverifikasi | Diizinkan |
| `community` | Dari komunitas | Perlu persetujuan eksplisit |

`HookPolicy` di SDK menolak hook dari tier komunitas kecuali pengguna
menyetujui (`--yes`). Installer fase fondasi tidak mengeksekusi hook otomatis;
extension yang memiliki hook dilaporkan agar pengguna memutuskan.

Registry fase berikutnya menambahkan checksum arsip, signature/metadata rilis,
dan pemeriksaan trust sebelum install.
