# Aturan menulis ulang potongan folder-structure.md

## Konteks

Kiln adalah monorepo (CLI + SDK + `kiln_core`) yang meng-generate aplikasi
Flutter lewat "extension" (manifest `extension.yaml` + Mason brick). Dokumen
`folder-structure.md` adalah **cetak biru untuk membangun proyek Kiln dari
nol**. Karena dibangun dari nol, tidak ada lagi pembeda "sudah ada" dan
"baru": semua file dianggap akan dibuat.

Tugasmu: menulis ulang SATU potongan dokumen (baris tertentu dari
`Test AI/kiln/docs/_wip/source.md`) supaya:

1. semua penanda "baru" hilang, dan
2. **setiap file dan folder di pohon punya deskripsi singkat dan jelas.**

Kamu bukan pemilik desain. Jangan menambah, menghapus, atau memindahkan file
(kecuali penggantian nama di aturan 8). Tugasmu hanya redaksional.

## Cara kerja

1. Baca `Test AI/kiln/docs/_wip/source.md` pada rentang baris yang diberikan
   (read_file dengan start_line dan end_line). Baca juga kontrak di bagian
   `kiln_core` dokumen itu (baris 245-316) bila perlu memahami istilah.
2. Tulis hasilnya ke `Test AI/kiln/docs/_wip/part_<NN>.md` dengan write_file.
   Bila hasilnya terlalu panjang untuk satu panggilan, pecah menjadi
   `part_<NN>a.md`, `part_<NN>b.md`, dan seterusnya, tepat di batas antar
   bagian (jangan memotong di tengah blok kode).
3. Hasil berisi persis rentang yang ditugaskan: tidak ada kalimat
   pengantar/penutup tambahan dan tidak ada pembungkus. Mulai dari baris
   pertama rentang, akhiri di baris terakhirnya.
4. Balas dengan pesan singkat: nama file yang ditulis, jumlah baris, dan hal
   yang meragukan. Jangan menyalin isi hasil ke balasan.

## Aturan penulisan

1. **Hapus penanda "baru"**: `# baru`, `# baru:` (pertahankan deskripsi
   sesudah titik dua), `(baru)`, `# baru dalam folder ini`, `# baru, seluruh
   folder`. Kata "baru" tidak boleh tersisa sebagai penanda status. Penanda
   `# generate` diganti menjadi bagian deskripsi, mis. `generate dari ...,
   jangan diedit`.
2. **Setiap baris pohon wajib punya komentar.** Setiap baris yang memakai
   `├─` atau `└─` harus berakhir dengan `# deskripsi`. Tidak boleh ada baris
   file atau folder tanpa komentar (termasuk `lib/`, `test/`, `docs/`,
   `fixtures/`, `widgets/`, `hooks/`, `__brick__/`).
3. **Satu file atau folder per baris.** Pecah baris yang memuat beberapa
   entri. Contoh: `├─ a_test.dart, b_test.dart  # baru` menjadi dua baris
   dengan deskripsi masing-masing. `├─ kiln.yaml, kiln.lock.yaml, pubspec.yaml`
   menjadi tiga baris. `├─ fresh_app/, app_with_dio/` menjadi dua baris.
   Cabang (`├─` dan `└─`) harus tetap benar: entri terakhir di sebuah folder
   memakai `└─`, yang lain `├─`, dan garis vertikal `│` diteruskan dengan
   benar untuk anak-anaknya.
4. **Bentuk deskripsi**: bahasa Indonesia, satu klausa berisi 3 sampai 12
   kata (maksimal sekitar 90 karakter), tanpa titik di akhir, menyatakan
   *apa yang dikerjakan file itu*, bukan mengulang namanya.
   - Buruk: `# helper cache`. Bagus: `# membuat kunci cache dari URL, query, dan header Vary`.
   - File test: awali dengan `menguji ...` dan sebut perilaku utamanya.
     Contoh: `# menguji bahwa kegagalan sementara diulang sesuai kebijakan`.
   - `*_module.dart`: `mendaftarkan <apa> ke Registry`.
   - `*_gateway.dart`: `membungkus <plugin> agar bisa di-fake di test`.
   - `*_failure_mapper.dart`: `mengubah error <sumber> menjadi Failure`.
   - `*_config.dart`: `konfigurasi bertipe: <isi utama>`.
   - `*_contract_test.dart`: `menjalankan suite kontrak <nama> dari kiln_testing ke implementasi ini`.
   - Folder: jelaskan isinya, mis. `# widget siap pakai untuk fitur ini`.
   - Jangan memakai kata kosong seperti "helper", "util", "dll", atau
     "berbagai" tanpa konteks.
5. **Baris `extension.yaml`** memakai format `# manifest: ...` berisi field
   penting yang sudah tertulis di komentar aslinya (provides, requires,
   category, exclusive, slot atau contributes, prompts, platform). Ringkas,
   maksimal sekitar 140 karakter. Buang `(baru)` di dalamnya.
6. **Blok `test/` tingkat extension.** Setiap baris
   `├─ test/    # manifest_test, render_test, analyze_test, goldens/rendered/`
   di pohon extension diganti persis dengan blok berikut (indentasi pohon
   extension sama di semua extension):

   ```text
   ├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
   │  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
   │  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
   │  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
   │  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
   ```

   Hanya berlaku untuk pohon `extensions/<id>/`. Blok standar di bagian
   "Konvensi" ditangani orang lain; jangan disentuh bila di luar rentangmu.
7. **Struktur dipertahankan.** Urutan, hierarki, dan jumlah file sama dengan
   sumber (setelah pemisahan baris pada aturan 3 dan penggantian nama pada
   aturan 8). Judul, paragraf, tabel, dan diagram mermaid dipertahankan
   apa adanya, kecuali kalimat yang membahas status "baru", "sudah ada",
   "sebelumnya", "sekarang", "dipindah", atau "nama tidak diubah": tulis ulang
   kalimat itu seolah proyek dibuat dari nol, atau hapus bila hanya
   membicarakan perbandingan dengan kondisi lama.
8. **Penamaan pemeta error disatukan** di seluruh dokumen:
   - `firebase_failures.dart` menjadi `firebase_failure_mapper.dart`
   - `supabase_failures.dart` menjadi `supabase_failure_mapper.dart`
   - `social_failures.dart` menjadi `social_login_failure_mapper.dart`
   - `analytics_failures.dart` menjadi `analytics_failure_mapper.dart`
   - berkas test pasangannya ikut: `<nama>_failure_mapper_test.dart`.
   Bila setelah penggantian ada dua entri bernama sama dalam satu folder,
   gabungkan jadi satu entri. Hapus catatan seperti "pemeta error yang sudah
   ada, namanya tidak diubah (lihat Keputusan desain)".
9. **Hapus rujukan ke kondisi lama.** Contoh penulisan ulang:
   - `typedef LogSink dipindah dari console_logger.dart bersama interface sink`
     menjadi `kontrak sink dan typedef LogSink`
   - `fasad Biometric yang sudah ada` menjadi
     `fasad Biometric: canAuthenticate dan authenticate`
   - `tabel kode dan pesan dipindah dari biometric.dart` menjadi
     `tabel kode error plugin ke FailureCode beserta pesannya`
   - `(brick ini sebelumnya tidak punya module)` dihapus
   - `(sekarang lewat HttpPipeline.use)` menjadi `(ditempelkan ke HttpPipeline)`
   - `dipindah dari src/` dihapus; tulis tujuan file saja.
10. Dalam blok kode jangan memakai backtick. Istilah teknis tetap dalam
    ejaan aslinya (Registry, Failure, Clock, Slot, AppLogger, dst).
11. Format komentar: dua spasi atau lebih sebelum `#`, satu spasi sesudahnya.
    Perataan kolom akan dirapikan otomatis nanti, tidak perlu manual.

## Kosakata kontrak (untuk menulis deskripsi test dan file)

`kiln_core` memuat: `Storage` (key-value), `SecureStorage`, `HttpClient`,
`HttpMiddleware`, `HttpPipeline`, `HttpCache`, `AuthRepository`, `SocialAuth`,
`SocialLogin`, `AccountManagement` (reset password, verifikasi email, ubah
profil), `LocalDatabase`, `RemoteDatabase`, `FileStorage`, `NetworkMonitor`,
`Permissions`, `Notifications`, `DeepLinks`, `MediaPicker`, `Analytics`,
`CrashReporter`, `AppLogger`, `Env`, `AppFlavor`, `Failure`, `FailureCode`,
`Result<T>`, `Registry`, `KilnModule`, `SessionController`, `TokenProvider`,
`ConsentController`, `PiiRedactor`, `Clock`, `Debouncer`, `OrderedSlot<T>`,
`Lifecycle`, `KilnBootstrap`.

Slot: `registry` (bawaan), `http.interceptors` (dibuka `dio`, item
`HttpMiddleware`), `router.routes` (dibuka `go_router`, item `AppRoute`),
`app.wrappers` (bawaan `app_basic`, item `AppWrapper`).

`kiln_testing` memuat fake per kontrak, suite `*_contract.dart` per kontrak,
dan harness test (`test_registry`, `pump_app`, matchers, async helpers).
