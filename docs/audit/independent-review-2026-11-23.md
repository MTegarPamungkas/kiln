# Review independen SDK Kiln

**Tanggal** 23 November 2026 · **Baseline kode** `fbb6c96`

> Temuan di bawah mencatat perilaku pada baseline. Status perbaikan sekarang
> ada di [audit backlog](current-status.md). Berkas repro kini menjalankan
> regresi terhadap perilaku setelah perbaikan.

Cakupan review meliputi bootstrap dan kontrak publik `kiln_core`, transaksi
`kiln_extension_sdk`, scaffolding `kiln_cli`, serta konsistensi katalog
`kiln_store`. Identitas N1–N5 mengikuti draf awal. N6–N8 melanjutkan review
tersebut. [Penerimaan perangkat dan penyedia](findings.md)

Lanjutan lintas paket, extension, dan distribusi tersedia di
[Audit pengembangan SDK](sdk-development-audit-2026-11-23.md).

## Ringkasan

Arsitektur contract-first memberi aplikasi jalur akses yang konsisten melalui
`Gate`, `Registry`, `Result` dan `Failure`. Installer mencatat perubahan
sebelum menulis file, dan registry memverifikasi checksum arsip. Tiga kasus
yang paling perlu ditangani adalah rollback yang bisa melaporkan sukses saat
snapshot hilang (N6), startup yang batal saat provider tersaring platform (N1),
dan transaksi yang luput dari pencarian rollback saat commit terputus (N8).

| Prioritas | Temuan | Dampak | Bukti |
| --- | --- | --- | --- |
| Tinggi | N6 · Rollback menerima snapshot yang hilang | File gagal dipulihkan dan journal terhapus | Reproduksi |
| Tinggi | N1 · Provider tersaring sebelum validasi graph | Fitur opsional bisa menggagalkan startup aplikasi | Reproduksi |
| Sedang | N8 · Journal luput dari pencarian selama commit | Perubahan masih ada, tetapi rollback dan doctor tidak menemukan transaksi itu | Simulasi status commit |
| Sedang | N2 · Dependensi Git bawaan mengikuti branch default | Pembuatan proyek baru dapat memilih revisi berbeda dari CLI yang sama | Kode dan tes CLI |
| Rendah–sedang | N7 · Cleanup registry bisa masih berjalan setelah `await dispose()` | Pemanggil kedua dapat melanjutkan terlalu dini | Reproduksi |
| Rendah–sedang | N3 · Riwayat backup tanpa retensi | Penggunaan disk bertambah seiring transaksi yang menyimpan riwayat | Inspeksi kode |
| Rendah | N4 · Dokumentasi kesetaraan `Failure` berbeda dari implementasi | Deduplikasi dapat menggabungkan kegagalan dengan detail berbeda | Reproduksi |
| Rendah | N5 · Jumlah extension di README meleset dan ada satu arsip lepas | README dan isi paket registry berbeda dari indeks aktif | Hitung manifest, indeks, dan arsip |

## Runtime dan kontrak publik

### N1 · Provider hilang dari graph saat platform disaring

Di Android, provider opsional yang hanya mendukung web dicatat sebagai
`unsupportedPlatform` dan dikeluarkan dari graph. Jika consumer aktif punya
`requires: {'http'}`, `ModuleGraph` melihat `http` sebagai capability tanpa
provider dan melempar `ModuleGraphException`. Proses berhenti sebelum bootstrap
bisa mencatat consumer sebagai `unavailable` dan melewati `ready()`. Cabang
`requiredForStartup` untuk provider yang tidak mendukung platform berjalan lebih
awal dan melempar `StateError` bila provider itu wajib. Reproduksi terpisah
mengonfirmasi kedua jalur. [Bootstrap](../../packages/kiln_core/lib/src/runtime/bootstrap.dart)
· [ModuleGraph](../../packages/kiln_core/lib/src/runtime/module_graph.dart)
· [Reproduksi](repro/independent_review_2026_11_23_test.dart)

Ini melengkapi K13. K13 sudah mencakup provider aktif yang melaporkan
`unavailable` dari support probe. Pada jalur tersebut graph masih mengenal
provider dan consumer dapat melewati `ready()`. Perilaku yang sama diharapkan
ketika provider opsional tersaring platform. Dio mendeklarasikan enam platform,
termasuk Linux. Reproduksi memakai modul sintetis; dampak pada kombinasi
extension bawaan belum dibuktikan. [Arsitektur](../architecture.md)
· [Manifest Dio](../../extensions/dio/extension.yaml)

**Saran.** Validasi graph aktif dengan membedakan capability yang tidak pernah
dideklarasikan dari capability yang hanya disediakan modul tersaring. Biarkan
bootstrap menghitung readiness dari capability yang benar-benar tersedia.
Uji provider tersaring dengan consumer opsional, consumer wajib, capability yang
diwajibkan aplikasi, dan capability tanpa provider sama sekali. Memasukkan semua
modul langsung ke graph juga menarik aturan duplicate provider dan siklus ke
modul yang tidak akan berjalan di platform aktif.

### N7 · Pemanggil kedua `Registry.dispose()` dapat selesai terlalu dini

`GetItRegistry.dispose()` mengatur `_disposed` sebelum menunggu callback
asinkron. Pemanggilan berikutnya langsung selesai meskipun callback pertama
masih tertahan dan registrasi masih ada. Reproduksi dengan `Completer`
menunjukkan keduanya. Jika cleanup pertama gagal, pemanggil kedua juga tidak
menerima error itu. `LifecycleController.dispose()` sudah menyimpan future
cleanup untuk dibagikan ke semua pemanggil. [Kontrak Registry](../../packages/kiln_core/lib/src/runtime/registry.dart)
· [GetItRegistry](../../packages/kiln_core/lib/src/runtime/get_it_registry.dart)
· [LifecycleController](../../packages/kiln_core/lib/src/runtime/lifecycle.dart)
· [Reproduksi](repro/independent_review_2026_11_23_test.dart)

**Saran.** Terapkan pola future bersama pada registry dan blokir registrasi
baru sejak disposal dimulai. Uji dua pemanggil yang menunggu cleanup yang sama,
termasuk saat callback melempar.

### N4 · Dokumentasi equality `Failure` perlu diselaraskan

Komentar API menyebut `details` sebagai bagian dari equality. `==` dan
`hashCode` memakai `code`, `message`, `kind`, serta `isRetryable`.
`details`, `cause`, dan `stackTrace` diabaikan. Dua instance yang hanya berbeda
di `details['request_id']` dianggap sama oleh `Set` atau saat dijadikan key
`Map`. [Implementasi](../../packages/kiln_core/lib/src/errors/failure.dart)
· [Reproduksi](repro/independent_review_2026_11_23_test.dart)

**Saran.** Dokumentasikan field yang benar dan pertahankan semantik equality
saat ini. Jika detail kelak menjadi bagian dari identitas kegagalan, definisikan
dulu kesetaraan dan hashing untuk nilai bersarang.

## Transaksi dan pemulihan

### N6 · Rollback melaporkan sukses walau snapshot yang dibutuhkan hilang

`Rollback.run()` memvalidasi path di journal sebelum mulai memulihkan file.
`SnapshotStore.restore()` diam-diam kembali ketika snapshot tidak ada. Pada
reproduksi, file awal berisi `old`, transaksi menulis `new`, lalu snapshot
dihapus. Rollback selesai tanpa error, meninggalkan `new`, serta menghapus
journal dan direktori backup. Perilaku yang sama berlaku pada jalur restore
untuk operasi delete. CLI mencetak pesan sukses jika `Rollback.run()` selesai
tanpa error. [Rollback](../../packages/kiln_extension_sdk/lib/src/installer/transaction/rollback.dart)
· [SnapshotStore](../../packages/kiln_extension_sdk/lib/src/installer/transaction/snapshot.dart)
· [Perintah rollback](../../packages/kiln_cli/lib/src/commands/rollback_command.dart)
· [Reproduksi](repro/independent_review_2026_11_23_test.dart)

**Saran.** Periksa keberadaan snapshot untuk setiap operasi yang perlu restore
sebelum mengubah proyek. Laporkan error dengan ID transaksi dan path yang
terdampak. Pertahankan journal serta snapshot yang tersisa agar perbaikan bisa
dicoba ulang. Ini menambah cakupan K22 untuk snapshot yang tidak lengkap.

### N8 · Journal bisa tertinggal di antara dua lokasi pencarian

`Transaction.commit()` memanggil `journal.markCommitted()` lebih dulu,
kemudian memindahkan journal ke `.kiln/backups/<id>/journal.json`. Jika proses
berhenti setelah status `committed` ditulis dan sebelum file dipindah, journal
masih berada di `.kiln/journal/`. `latestInterrupted()` hanya menerima
`running` dari lokasi tersebut, sedangkan `latestCommitted()` hanya memindai
folder backup. Akibatnya, `kiln rollback` bisa memilih transaksi lebih lama
jika ada, dan pemeriksaan interrupted operation di `kiln doctor` melewatkan
transaksi yang tertinggal. [Commit](../../packages/kiln_extension_sdk/lib/src/installer/transaction/transaction.dart)
· [Pencarian journal](../../packages/kiln_extension_sdk/lib/src/installer/transaction/rollback.dart)
· [Doctor](../../packages/kiln_cli/lib/src/commands/doctor_command.dart)

Temuan dikonfirmasi di direktori sementara dengan menulis file lewat
`Transaction`, memanggil `tx.journal.markCommitted()`, lalu menjalankan kedua
pencarian. File baru, journal, dan snapshot masih ada; kedua pencarian
mengembalikan `null`. Langkah ini menyimulasikan keadaan setelah interupsi.
Tes K22 yang menghentikan proses di tengah penulisan menguji keadaan
`running`. [Tes pemulihan yang ada](../../packages/kiln_extension_sdk/test/rollback_test.dart)

**Saran.** Definisikan titik commit yang tetap dapat ditemukan setelah proses
berhenti. Uji kegagalan sebelum dan sesudah status ditulis serta sebelum dan
sesudah journal dipindah. Sertakan riwayat lama agar pemulihan selalu memilih
transaksi yang tepat.

### N3 · Riwayat rollback tumbuh tanpa retensi otomatis

`Transaction.commit()` default ke `keepHistory: true`. Commit yang menyimpan
riwayat menaruh journal beserta salinan versi lama dari file yang dicadangkan di
`.kiln/backups/<id>/`. Installer memakai default ini pada mutasi seperti add,
remove, upgrade, dan perubahan konfigurasi yang dijalankan lewat setup. Setup
tanpa argumen menampilkan status. Template mengabaikan `.kiln/backups/`
secara khusus. Rollback menghapus backup transaksi yang berhasil dibalik.
Tidak ditemukan batas umur atau jumlah untuk riwayat yang tersisa.
[Transaction](../../packages/kiln_extension_sdk/lib/src/installer/transaction/transaction.dart)
· [Installer](../../packages/kiln_extension_sdk/lib/src/installer/extension_installer.dart)
· [Setup](../../packages/kiln_cli/lib/src/commands/setup_command.dart)
· [Template gitignore](../../bricks/app_basic/__brick__/.gitignore)

**Saran.** Terapkan retensi yang terdokumentasi untuk transaksi selesai.
Selesaikan penanganan journal yang tertinggal (N8) sebelum cleanup otomatis,
agar snapshot untuk transaksi yang masih perlu dipulihkan tetap terjaga.

## Distribusi dan katalog

### N2 · Fallback Git bawaan `kiln create` tidak mematok revisi

Saat tidak ada checkout lokal atau sumber eksplisit, `kiln create` menulis URL
Git bawaan tanpa `ref` untuk `kiln_core` dan `kiln_testing`. Tes CLI fallback
secara eksplisit mengharapkan `ref` kosong. Resolusi awal karena itu mengikuti
HEAD branch default. Dua proyek baru yang dibuat dengan CLI yang sama dapat
mendapat revisi berbeda. Untuk proyek yang sudah punya `pubspec.lock`, Pub
mencatat revisi Git hasil resolusi. `kiln.lock.yaml` mengunci extension dan
berperan terpisah. [CreateCommand](../../packages/kiln_cli/lib/src/commands/create_command.dart)
· [Tes fallback](../../packages/kiln_cli/test/commands/create_command_test.dart)
· [Dependensi Git Pub](https://dart.dev/tools/pub/dependencies)
· [Lockfile Pub](https://dart.dev/tools/pub/cmd/pub-get)

**Saran.** Isi ref bawaan dengan SHA commit rilis yang kompatibel untuk kedua
paket, dan uji pembuatan aplikasi tanpa checkout lokal dari artefak CLI rilis.
Alternatifnya, gunakan tag dengan pemetaan rilis yang divalidasi. Versi CLI
lokal adalah `0.1.1` dan tag `v0.1.1` tidak ada di checkout ini, sehingga
membentuk tag secara mekanis dari versi CLI perlu validasi tambahan.
[Versi CLI](../../packages/kiln_cli/lib/src/version.dart)
· [Workflow rilis](../../.github/workflows/release.yaml)

### N5 · README menghitung 35 extension, katalog aktif berisi 34

Ada 34 manifest extension dan 34 entri di `registry/index.json`. Dari 59 file
di `registry/archives/`, 58 direferensikan oleh versi dalam indeks. Satu file
yang tersisa adalah `neon-0.1.0.tgz`, terkait Neon yang dihentikan di K05.
`tool/registry.dart --check` tetap lulus karena menyalin arsip lama ke
direktori pemeriksaan dan tidak menguji apakah setiap file punya referensi
indeks. [README](../../README.md) · [Indeks registry](../../registry/index.json)
· [Pemeriksaan registry](../../tool/registry.dart)

**Saran.** Selaraskan jumlah di README atau turunkan dari katalog. Tentukan
kebijakan untuk arsip extension yang dihentikan sebelum menghapus Neon, karena
proyek lama bisa menyimpan URL arsip secara langsung. Jika arsip semacam ini
boleh dipertahankan, pemeriksaan katalog perlu mencatat pengecualiannya.

## Pemeriksaan dan batas bukti

| Pemeriksaan | Hasil |
| --- | --- |
| `dart test docs/audit/repro/independent_review_2026_11_23_test.dart` | 6 lulus. Tes karakterisasi N1, N4, N6, N7 mengunci perilaku yang diamati, termasuk bug. |
| Simulasi perpindahan journal saat commit | N8 terkonfirmasi. |
| `dart analyze` dari root | Lulus tanpa temuan dalam cakupan konfigurasi root. |
| `dart analyze docs/audit/repro` | 1 lint info (`depend_on_referenced_packages`). Repro mengimpor `kiln_core`, yang tersedia lewat workspace tetapi tidak dideklarasikan langsung di `pubspec.yaml` root. |
| `kiln_core` dan `kiln_store` | 191 dan 95 lulus. |
| `kiln_extension_sdk` | 184 lulus pada pengulangan. Putaran pertama 183 lulus dan 1 gagal di tes snapshot. |
| `kiln_cli` | 160 lulus. |
| `bundle`, `registry`, `verify_extensions`, `gen_catalog_docs`, `check_versions`, `check_docs`, `lint_extensions` dengan `--check` | Seluruhnya exit 0. |
| `tool/check_metadata.dart` | Lulus. Metadata manifest dan modul konsisten. |

- Kontrol untuk `optionalRequires` lulus: consumer tetap menjalankan `ready()`
  saat provider opsional yang aktif melaporkan `unavailable`.
  [Reproduksi](repro/independent_review_2026_11_23_test.dart)
- Pada jalur normal, transaksi mencadangkan file sebelum perubahan dan rollback
  memeriksa path sebelum melakukan restore. N6 dan N8 membatasi jaminan
  pemulihan saat snapshot hilang atau proses berhenti pada tahap commit.
- `LifecycleController` membagikan future disposal, menjalankan callback
  dengan urutan terbalik, dan meneruskan error pertama setelah semua callback
  dicoba. Dokumentasi arsitektur publik sudah menyebut bahwa timeout tidak
  membatalkan pekerjaan plugin. [Arsitektur](../architecture.md)
- Pencarian statis menemukan 26 dari 34 extension yang memuat import dari
  `package:kiln_testing/` di sumber Dart. File tes dari 17 extension memanggil
  fungsi suite kontrak publik. Angka ini mengukur pemanggilan di sumber.
  Cakupan adapter dan perangkat mengikuti bukti K23.
  [Kiln testing](../../packages/kiln_testing/README.md) · [K23](findings.md#k23--appwrite-push-routing-and-device-delivery)
- Tes `SnapshotStore backs up once and restores the original content` gagal
  pada putaran pertama, lalu lulus saat dijalankan sendiri dan pada pengulangan
  suite. Tes memanggil `file.writeAsString('after')` tanpa `await` tepat sebelum
  restore sinkron, sehingga kedua operasi dapat berlomba.
  [Tes snapshot](../../packages/kiln_extension_sdk/test/snapshot_test.dart)
- Analyzer root mengecualikan `docs/**`, brick, dan beberapa fixture. Analisis
  repro dijalankan terpisah. [Konfigurasi analyzer](../../analysis_options.yaml)
- Golden render, analisis dan tes brick hasil render, komposisi extension, serta
  uji perangkat menjawab pertanyaan berbeda. Review ini menjalankan
  `verify_extensions --check` untuk golden render. Analisis dan tes semua brick
  hasil render, fixture gabungan, dan pengujian perangkat tidak dijalankan ulang.
  [CI](../../.github/workflows/ci.yaml) · [Status audit](current-status.md)
