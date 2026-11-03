# Native flavors not included

Extension ini tidak membuat product flavor Android atau scheme/build
configuration iOS. Yang dibuat hanya:

- nilai `AppFlavor` di Dart,
- entry point per flavor,
- file env per flavor,
- konfigurasi launch editor.

Alasannya, product flavor native menyentuh Gradle, Xcode project, dan signing
yang berbeda per proyek. Kiln tidak menebak konfigurasi tersebut.

Bila aplikasi membutuhkan applicationId atau bundle id berbeda per flavor,
tambahkan product flavor native secara manual, lalu gunakan `--flavor` pada
perintah Flutter. Nilai `AppFlavor` tetap dapat dipakai untuk perilaku Dart.
