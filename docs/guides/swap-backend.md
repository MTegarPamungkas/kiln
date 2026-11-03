# Mengganti backend

Target: kode fitur tidak berubah saat backend diganti.

## Prinsip

- Fitur memakai kontrak `AuthRepository`, `RemoteDatabase`, dan `FileStorage`
  dari `kiln_core`.
- Backend (`appwrite`, `firebase`, `supabase`) adalah extension exclusive yang
  menyediakan tiga kontrak tersebut.
- Tidak ada impor tipe konkret backend di `features/`.

## Langkah (fase 2)

1. Pastikan fitur membaca kontrak dari Registry.
2. `kiln remove supabase` (file yang diedit akan dilaporkan).
3. `kiln add appwrite` dan isi prompt endpoint/project/database/bucket.
4. Jalankan `kiln doctor`, lalu test contract backend.
5. Bandingkan `lib/extensions/`; kode fitur tetap sama.

`examples/backend_swap` akan menjadi bukti kedua varian saat extension backend
tersedia.
