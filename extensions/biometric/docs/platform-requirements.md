# Platform requirements

## Android

- Extension menambahkan izin `USE_BIOMETRIC`.
- Activity utama diganti menjadi `FlutterFragmentActivity`; plugin
  `local_auth` membutuhkannya untuk menampilkan prompt.
- Prompt bawaan memakai `BiometricPrompt` pada Android 9 ke atas dan
  kompatibilitas AppCompat pada versi lebih lama.

## iOS dan macOS

- Extension menambahkan `NSFaceIDUsageDescription`.
- Pengguna harus sudah mendaftarkan Face ID atau Touch ID di perangkat.
- Simulator dapat melaporkan hardware tanpa enrollment; uji di perangkat
  untuk alur penuh.

## Web dan desktop

Extension ini tidak mendukung web. Status `unsupportedPlatform` dikembalikan,
dan `authenticate()` melempar `Failure(unavailable)`. Windows dan Linux juga
tidak termasuk platform extension ini walau `local_auth` punya implementasi
eksperimental.
