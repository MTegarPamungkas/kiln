# 0003 — Hook berjalan dengan konfirmasi berdasarkan trust tier

## Keputusan

Hook hanya diizinkan untuk extension `official`/`verified` atau setelah
persetujuan eksplisit pengguna. Fase fondasi tidak mengeksekusi hook otomatis;
hook yang ada dilaporkan.

## Alasan

Hook menjalankan kode arbitrer di mesin pengguna. Permukaan kepercayaan harus
sekecil mungkin. Validasi deklaratif (prompt) lebih aman daripada hook.

## Konsekuensi

- `dio` tidak memakai hook; validasi URL/int dilakukan `PromptSpec`.
- `codegen` kelak membutuhkan hook karena menjalankan `build_runner`.
- `firebase` dapat memakai `manual_steps` + doctor daripada hook.
