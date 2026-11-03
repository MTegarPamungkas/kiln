## kiln_cli

CLI hanya mengurus interaksi: parsing perintah, prompt, laporan, dan kode
keluar. Semua logika pemasangan ada di `kiln_extension_sdk`, sehingga setiap
command tipis dan mudah dites.

```text
packages/kiln_cli/
├─ bin/  # titik masuk executable kiln
│  └─ kiln.dart  # fungsi main yang menjalankan command runner lalu keluar dengan kodenya
├─ lib/  # kode pustaka CLI yang dipakai bin/kiln.dart dan test/
│  ├─ kiln_cli.dart  # barrel yang mengekspor API publik kiln_cli
│  └─ src/  # implementasi internal CLI: perintah, infra, dan bundle
│     ├─ command_runner.dart  # mendaftarkan semua perintah dan meneruskan argumen ke perintah yang sesuai
│     ├─ project_context.dart  # mendeteksi proyek kiln lalu membaca kiln.yaml dan lockfile
│     ├─ paths.dart  # menyusun path kiln.yaml, lockfile, dan direktori ~/.kiln
│     ├─ version.dart  # konstanta versi CLI untuk perintah version dan update checker
│     ├─ commands/  # implementasi tiap subperintah CLI, satu file per perintah
│     │  ├─ create_command.dart  # perintah create: membuat proyek dari app_basic dengan state management pilihan
│     │  ├─ add_command.dart  # perintah add: memasang extension secara transaksional lewat SDK
│     │  ├─ remove_command.dart  # perintah remove: melepas extension dan hanya menghapus file yang belum diedit
│     │  ├─ list_command.dart  # perintah list: menampilkan extension terpasang atau tersedia
│     │  ├─ doctor_command.dart  # perintah doctor: memeriksa kesehatan proyek, bisa memperbaiki lewat --fix
│     │  ├─ version_command.dart  # perintah version: menampilkan versi CLI dan kiln_core
│     │  ├─ command_helpers.dart  # opsi dan alur bersama antar perintah, misalnya --dry-run dan --yes
│     │  ├─ info_command.dart  # perintah info: menampilkan provides, requires, platform, dan changelog extension
│     │  ├─ upgrade_command.dart  # perintah upgrade: menaikkan versi extension lalu menjalankan migration
│     │  ├─ rollback_command.dart  # perintah rollback: membalikkan operasi terakhir dari jurnal
│     │  ├─ graph_command.dart  # perintah graph: mencetak graf requires dan capability dalam text atau mermaid
│     │  ├─ config_command.dart  # perintah config: mengatur registry, mirror, dan mode offline
│     │  ├─ cache_command.dart  # perintah cache: melihat dan membersihkan cache registry
│     │  ├─ store_command.dart  # perintah store: mencari dan melihat extension di registry
│     │  ├─ completion_command.dart  # perintah completion: mencetak skrip autocomplete bash, zsh, dan fish
│     │  └─ ext/  # subperintah kiln ext: alat untuk penulis extension
│     │     ├─ ext_new_command.dart  # perintah ext new: membuat kerangka extension beserta manifest dan brick
│     │     ├─ ext_validate_command.dart  # perintah ext validate: memeriksa extension.yaml terhadap schema
│     │     ├─ ext_test_command.dart  # perintah ext test: menjalankan test extension, bisa --update-goldens
│     │     ├─ ext_pack_command.dart  # perintah ext pack: mengemas extension menjadi arsip untuk registry
│     │     └─ ext_publish_command.dart  # perintah ext publish: menerbitkan arsip extension ke registry
│     ├─ infra/  # layanan pendukung CLI: log, prompt, laporan, konfigurasi, dan akses sistem
│     │  ├─ kiln_logger.dart  # mencatat log berlevel dan progres, mengikuti --verbose dan --quiet
│     │  ├─ prompter.dart  # menampilkan prompt interaktif, menghormati --yes dan mendeteksi non-TTY
│     │  ├─ exit_codes.dart  # kode keluar tetap untuk tiap hasil perintah, dipakai CI
│     │  ├─ json_reporter.dart  # melaporkan hasil perintah sebagai JSON saat --json aktif
│     │  ├─ error_presenter.dart  # mengubah KilnException menjadi pesan beserta saran perbaikan
│     │  ├─ global_config.dart  # konfigurasi bertipe: registry, mirror, dan mode offline dari ~/.kiln/config.yaml
│     │  ├─ update_checker.dart  # memberi tahu adanya versi CLI lebih tinggi tanpa memblokir perintah
│     │  ├─ process_runner.dart  # menjalankan proses eksternal seperti flutter dan dart dengan keluaran terkontrol
│     │  └─ file_system.dart  # abstraksi file system supaya perintah bisa dites tanpa disk
│     └─ bundles/  # bundle semua extension, generate dari extensions/, jangan diedit
│        ├─ catalog.g.dart  # katalog extension tersedia, generate dari extension.yaml, jangan diedit
│        ├─ app_basic_bundle.dart  # bundle app_basic untuk create, generate dari extensions/app_basic, jangan diedit
│        └─ <id>_bundle.dart  # bundle per extension (29 file), generate dari extensions/<id>, jangan diedit
├─ test/  # test paket kiln_cli: command runner, perintah, infra, fixture, dan golden
│  ├─ command_runner_test.dart  # menguji pemetaan argumen ke perintah dan kode keluar command runner
│  ├─ commands/  # satu file test untuk tiap perintah CLI
│  │  ├─ create_command_test.dart  # menguji create membuat proyek dari app_basic sesuai opsi state dan platform
│  │  ├─ add_command_test.dart  # menguji add memasang extension secara transaksional, termasuk mode dry-run
│  │  ├─ remove_command_test.dart  # menguji remove hanya menghapus file yang belum diedit user
│  │  ├─ list_command_test.dart  # menguji list menampilkan extension terpasang dan tersedia, termasuk --json
│  │  ├─ doctor_command_test.dart  # menguji doctor melaporkan hash berubah, patch hilang, dan sisa jurnal
│  │  ├─ info_command_test.dart  # menguji info menampilkan provides, requires, platform, dan changelog
│  │  ├─ upgrade_command_test.dart  # menguji upgrade menaikkan versi extension lalu menjalankan migration
│  │  ├─ rollback_command_test.dart  # menguji rollback membalikkan operasi terakhir berdasarkan jurnal
│  │  ├─ graph_command_test.dart  # menguji graph mencetak graf requires dalam format text dan mermaid
│  │  ├─ config_command_test.dart  # menguji config mengatur registry, mirror, dan mode offline
│  │  ├─ cache_command_test.dart  # menguji cache menampilkan dan membersihkan cache registry
│  │  ├─ store_command_test.dart  # menguji store mencari dan menampilkan extension dari registry
│  │  └─ ext_commands_test.dart  # menguji subperintah ext: new, validate, test, pack, dan publish
│  ├─ infra/  # test komponen infra: prompter, reporter JSON, error presenter, dan kode keluar
│  │  ├─ prompter_test.dart  # menguji prompt interaktif, mode --yes, dan deteksi non-TTY
│  │  ├─ json_reporter_test.dart  # menguji json_reporter menghasilkan keluaran --json yang stabil
│  │  ├─ error_presenter_test.dart  # menguji KilnException menjadi pesan beserta saran perbaikan
│  │  └─ exit_codes_test.dart  # menguji kode keluar tetap yang dipakai CI tidak berubah
│  ├─ fixtures/  # proyek kecil per skenario sebagai bahan uji perintah
│  │  ├─ fresh_app/  # proyek hasil create tanpa extension tambahan, titik awal skenario
│  │  ├─ app_with_dio/  # proyek dengan extension dio terpasang beserta lockfile
│  │  ├─ app_with_edited_files/  # proyek dengan file render yang sudah diedit user, untuk uji hash dan remove
│  │  ├─ app_with_flavors/  # proyek dengan beberapa AppFlavor, untuk menguji konfigurasi per flavor
│  │  └─ app_without_lock/  # proyek tanpa kiln.lock.yaml, untuk menguji deteksi proyek dan doctor
│  └─ goldens/  # keluaran perintah acuan yang harus tetap sama
│     ├─ add_dry_run.txt  # mengunci keluaran teks add --dry-run: rencana file dan patch
│     ├─ add_dry_run.json  # mengunci keluaran JSON add --dry-run yang dibaca CI
│     ├─ doctor_report.txt  # mengunci laporan teks doctor beserta saran perbaikan
│     ├─ list.json  # mengunci keluaran list --json: extension terpasang dan tersedia
│     └─ info_dio.txt  # mengunci keluaran teks info untuk extension dio
├─ analysis_options.yaml  # aturan lint dan analisis statis untuk paket kiln_cli
├─ CHANGELOG.md  # catatan perubahan tiap rilis kiln_cli
├─ pubspec.yaml  # metadata dan dependensi paket kiln_cli
└─ README.md  # pengantar, instalasi, dan contoh pemakaian CLI
```

### Daftar perintah

| Perintah | Fungsi | Flag penting |
| --- | --- | --- |
| `create` | buat proyek dari `app_basic`, pilih state management | `--state`, `--org`, `--platforms`, `--with` |
| `add` | pasang extension secara transaksional | `--dry-run`, `--yes`, `--no-verify`, `--from` |
| `remove` | lepas extension, hanya hapus file yang belum diedit | `--dry-run`, `--force` |
| `upgrade` | naikkan versi extension lalu jalankan migration | `--dry-run`, `--all` |
| `rollback` | balikkan operasi terakhir dari jurnal | `--list` |
| `list` | extension terpasang atau tersedia | `--installed`, `--available`, `--json` |
| `info` | provides, requires, platform, dan changelog satu extension | `--json` |
| `graph` | graf requires dan capability | `--format text` atau `mermaid` |
| `doctor` | periksa kesehatan proyek | `--fix`, `--json` |
| `config` | atur registry, mirror, dan mode offline | `--global` |
| `cache` | lihat atau bersihkan cache registry | `clean` |
| `store` | cari dan lihat extension di registry | `search`, `info` |
| `completion` | skrip autocomplete shell | `bash`, `zsh`, `fish` |
| `ext` | alat penulis extension: `new`, `validate`, `test`, `pack`, `publish` | `--update-goldens`, `--tier` |
| `version` | versi CLI dan `kiln_core` | tidak ada |

### Yang diperiksa doctor

- Hash file hasil render di lockfile dibandingkan dengan kondisi sebenarnya,
  supaya file yang diedit user ketahuan.
- Patch native yang hilang atau ganda (permission, entitlement,
  intent-filter).
- `extensions.g.dart` yang tidak sinkron dengan lockfile.
- Langkah manual yang belum selesai, misalnya `flutterfire configure` untuk
  Firebase.
- Extension yang tidak mendukung platform proyek, misalnya `biometric` di web.
- Versi Dart, Flutter, dan `kiln_core` terhadap rentang `compatibility` tiap
  extension.
- Extension yang punya versi baru atau migration yang belum dijalankan.
- Sisa jurnal dari operasi yang terhenti di tengah jalan.
