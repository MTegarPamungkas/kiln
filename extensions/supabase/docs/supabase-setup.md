# Persiapan Supabase

Extension ini butuh satu project Supabase. Semua nilai yang dirender berasal
dari `extension.yaml`; nilai lain ada di `SupabaseConfig.defaults`.

## 1. Ambil URL dan anon key

Di dashboard Supabase buka **Project settings > API**:

- **Project URL** diisi ke prompt `url`, misalnya
  `https://abcdefgh.supabase.co`.
- **anon (publishable) key** diisi ke prompt `anon_key`.

Jangan pernah memakai **service role key** di aplikasi. Key itu melewati semua
policy RLS dan hanya untuk server.

## 2. Skema PostgREST

Prompt `schema` menentukan schema yang dipakai `RemoteDatabase` dan realtime.
Bawaannya `public`. Bila tabel tinggal di schema lain, ekspos schema tersebut di
**Project settings > API > Exposed schemas**, lalu isi prompt dengan namanya.

## 3. Konfigurasi bertipe

`SupabaseConfig.defaults` dirender ke `lib/extensions/supabase/supabase_config.dart`.
Nilai yang sering disesuaikan:

- `storageBucket` (bawaan `public`) — bucket untuk `FileStorage`.
- `authRedirectUrl` (bawaan `kiln-auth://auth-callback`) — dikirim ke Supabase
  untuk konfirmasi email, reset password, dan OAuth.
- `signedUrlLifetime` (bawaan 1 jam) — masa berlaku `FileStorage.url`.
- `authTimeout` (bawaan 5 menit) — batas menunggu sesi setelah OAuth.
- `usePkce` (bawaan `true`) — alur PKCE wajib untuk aplikasi mobile.
- `detectSessionInUri` (bawaan `false`) — biarkan mati karena callback dibaca
  `SupabaseLinkHandler` lewat kontrak `DeepLinks`.

`SupabaseConfig.validate()` bisa dipanggil lebih awal untuk memastikan URL,
anon key, schema, dan redirect valid. Pesan error tidak pernah memuat anon key.

## 4. Inisialisasi

`SupabaseModule.ready` memanggil `SupabaseClientProvider.load()` yang membuat
klien dengan `Supabase.initialize` (PKCE, auto refresh token, sesi persisten).
Klien dipakai bersama oleh semua gateway, jadi jangan membuat klien Supabase
kedua di aplikasi.

## 5. Bucket storage

`FileStorage` memakai satu bucket. Buat bucket tersebut di **Storage**, lalu
tambahkan policy pada `storage.objects` untuk folder yang dipakai aplikasi.
`url()` selalu mengembalikan signed URL, jadi bucket boleh privat.
