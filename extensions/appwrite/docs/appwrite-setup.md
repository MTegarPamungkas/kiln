# Setup Appwrite

Extension ini berbicara dengan Appwrite Cloud atau instance Appwrite yang
di-host sendiri. Selesaikan langkah berikut sebelum memakai kontraknya.

## 1. Buat project

1. Masuk ke console Appwrite dan buat project baru.
2. Salin **Project ID** dari halaman Settings. Nilai ini menjadi prompt
   `project_id`.
3. Salin endpoint API, misalnya `https://cloud.appwrite.io/v1` atau
   `https://appwrite.example.com/v1`, menjadi prompt `endpoint`.

## 2. Daftarkan platform

Appwrite menolak permintaan dari platform yang tidak terdaftar. Tambahkan
platform sesuai target aplikasi:

- Android: package name dari `applicationId`.
- iOS dan macOS: bundle identifier.
- Web: hostname tempat aplikasi disajikan.

Langkah manual `appwrite_platform` diingatkan oleh `kiln doctor` sampai
platform tersebut dibuat.

## 3. Database dan tabel

1. Buat database dengan id yang sama dengan prompt `database_id`.
2. Buat tabel untuk setiap koleksi yang dipakai `RemoteDatabase`. Argumen
   `collection` pada kontrak dipakai sebagai id tabel.
3. Tentukan kolom dan indeks. Filter dan `orderBy` membutuhkan indeks yang
   sesuai, sama seperti query Appwrite pada umumnya.

## 4. Bucket penyimpanan

1. Buat bucket dengan id yang sama dengan prompt `bucket_id`.
2. Pilih izin bucket. Untuk aplikasi yang hanya mengunggah berkas milik user,
   berikan izin `create` dan `read` kepada role `users`.
3. Atur batas ukuran dan tipe berkas sesuai kebutuhan aplikasi.

## 5. Redirect URL

Reset password dan verifikasi email mengarahkan user kembali ke aplikasi lewat
deep link. Appwrite 2.x tidak lagi memakai daftar redirect URL di Auth Settings;
skema divalidasi terhadap daftar platform project.

Skema mobile yang selalu diterima adalah
`appwrite-callback-<PROJECT_ID>://`. Extension memakai:

- `appwrite-callback-<PROJECT_ID>://auth/recovery`
- `appwrite-callback-<PROJECT_ID>://auth/verify`

Daftarkan intent filter Android untuk skema tersebut di `MainActivity`. Bila
aplikasi memakai skema lain, ganti `recoveryRedirectUrl` dan
`verificationRedirectUrl` pada `AppwriteAccountManagement` dan pastikan skema
itu terdaftar sebagai platform (tipe `scheme`) di project.

## 6. Development

`AppwriteClientFactory` hanya memanggil `setSelfSigned` pada flavor
`development`. Dengan begitu instance lokal yang memakai sertifikat sendiri bisa
dipakai saat mengembangkan aplikasi tanpa melonggarkan pemeriksaan sertifikat
di produksi.

Instance lokal tanpa TLS memakai endpoint `http://<host>/v1`. Dari emulator
Android, host mesin dijangkau lewat `http://10.0.2.2/v1`, bukan `localhost`.
Aktifkan `android:usesCleartextTraffic="true"` hanya pada build debug agar
Android mengizinkan HTTP.

Sesi email/password dibuat lewat HTTP dan cookie-nya diteruskan sebagai header
`X-Appwrite-Session`. Cookie jar bawaan SDK tidak selalu tersimpan pada endpoint
HTTP biasa, sehingga cara ini memastikan panggilan berikutnya sudah
terautentikasi. Nilai sesi disimpan lewat `shared_preferences`, dipulihkan pada
`AppwriteModule.ready`, dan dihapus saat sign-out.
