# Catatan pindah backend

Kontrak `AuthRepository`, `RemoteDatabase`, dan `FileStorage` sama dengan
extension Firebase dan Supabase, tetapi ada beberapa perbedaan perilaku yang
perlu diketahui saat memindahkan aplikasi ke Appwrite.

## Auth

- `signUp` membuat akun lalu langsung membuat sesi. Bila project mewajibkan
  verifikasi email sebelum masuk, panggilan ini gagal dengan
  `Failure(auth.email_not_verified)`.
- Sesi dibuat lewat HTTP dan cookie-nya dikirim sebagai header
  `X-Appwrite-Session`; nilainya disimpan di `shared_preferences` dan
  dipulihkan oleh `AppwriteModule.ready` saat aplikasi dibuka ulang.
- `AppwriteTokenProvider` membuat JWT 15 menit dan menyimpannya selama 14
  menit. Token ini dipakai untuk request HTTP yang membutuhkan bearer token,
  bukan untuk menggantikan sesi utama.
- Reset password dan verifikasi email memakai skema
  `appwrite-callback-<PROJECT_ID>://auth/recovery` dan `.../auth/verify`.
  Appwrite 2.x menerima skema itu tanpa daftar redirect URL.

## Database

- Tidak ada cache offline. Setiap `read` dan `query` memanggil jaringan; gunakan
  extension `local_db` bila aplikasi butuh mode offline.
- Nama koleksi dipetakan ke id tabel. Dokumen yang dikembalikan berisi `id` dan
  kolom biasa, tanpa kolom sistem Appwrite.
- `watch` mengirim dokumen saat ini lebih dulu, lalu perubahan realtime, dan
  mengirim null ketika dokumen dihapus. Langganan ditutup saat module
  di-dispose.
- Kombinasi filter dan urutan tetap membutuhkan indeks. Appwrite menolak query
  tanpa indeks dengan `Failure(remote_database.query_failed)` atau
  `Failure(remote_database.unavailable)`.

## Penyimpanan

- Path seperti `avatars/user-1.png` dipetakan ke id berkas Appwrite yang valid.
  Nama asli tetap terlihat di URL `view`.
- `expiresIn` pada `FileStorage.url` diabaikan karena SDK client tidak bisa
  membuat signed URL. Atur bucket sebagai publik atau buat signed URL dari
  server.
- `updatePhotoUrl` menyimpan URL di preferences user dengan kunci `photoUrl`,
  karena Appwrite tidak punya kolom foto profil bawaan.

## Pemetaan kegagalan

| Status | Failure |
| --- | --- |
| 400 | `validation.invalid_input` |
| 401 kredensial salah | `auth.invalid_credentials` |
| 401 email belum diverifikasi | `auth.email_not_verified` |
| 401 sesi hilang | `auth.session_expired` |
| 401 lainnya | `auth.unauthorized` |
| 403 | `permission.denied` |
| 404 database | `remote_database.not_found` |
| 404 storage | `file.not_found` |
| 409 database | `remote_database.conflict` |
| 409 storage | `file.upload_failed` |
| 429 | `network.server` dengan `isRetryable` |
| 5xx | `unavailable` dengan `isRetryable` |
| error jaringan | `network.unreachable` atau `network.unknown` |
