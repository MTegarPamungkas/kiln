# Langkah manual: flutterfire configure

Extension ini menandai `firebase_flutterfire_configure` sebagai langkah manual
yang dilacak `kiln doctor`. Hook Mason hanya memberi peringatan; instalasi tetap
selesai walaupun langkah ini belum dikerjakan.

## Yang harus ada

- `flutterfire` CLI tersedia di `PATH`.
- `lib/firebase_options.dart` berisi `DefaultFirebaseOptions.currentPlatform`.
- File native hasil generate: `google-services.json` (Android),
  `GoogleService-Info.plist` (iOS/macOS), dan konfigurasi web pada
  `firebase_options.dart`.

## Perintah

```bash
dart pub global activate flutterfire_cli
flutterfire configure \
  --project=<project-id> \
  --platforms=android,ios,macos,web
```

Jalankan ulang perintah tersebut setiap kali aplikasi Firebase baru
didaftarkan. Commit `lib/firebase_options.dart`; file ini tidak memuat secret
dan dibutuhkan oleh build CI.

## Bila memakai options eksplisit

Ubah prompt `options_source` menjadi `explicit` saat memasang extension, lalu
bangun `FirebaseOptions` dari konfigurasi build Anda sendiri dan teruskan ke
`FirebaseModule(options: ...)`. Hook tidak lagi memeriksa
`lib/firebase_options.dart`.
