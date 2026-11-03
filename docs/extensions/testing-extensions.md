# Menguji extension

Ada tiga lapis test.

## 1. Test di dalam brick

File di `brick/__brick__/test/extensions/<id>/` ikut dirender ke aplikasi
pengguna dan berjalan di sana. Contoh:

- test module mendaftarkan layanan ke Registry,
- test failure mapper,
- test widget/helper,
- `*_contract_test.dart` yang menjalankan suite dari `kiln_testing`.

## 2. Test tingkat extension

File di `test/` extension:

- `manifest_test.dart` — manifest valid terhadap schema dan validator.
- `render_test.dart` — render brick ke folder temp dan bandingkan golden.
- `analyze_test.dart` — hasil render lolos `flutter analyze`.

`ExtensionTestHarness` menyediakan `loadManifest`, `validateManifest`,
`bundle`, dan `render`.

## 3. Contract suite

`kiln_testing` menyediakan suite untuk HttpClient, Storage, SecureStorage,
AuthRepository, AccountManagement, SocialAuth, LocalDatabase, RemoteDatabase,
FileStorage, NetworkMonitor, Permissions, Notifications, DeepLinks,
MediaPicker, Analytics, CrashReporter, dan AppLogger.

Implementasi kontrak yang sama harus lolos suite yang sama. Itulah bukti bahwa
backend dan transport bisa diganti.

## Menjalankan

```bash
kiln ext test extensions/dio
```

Pada repo ini, setiap extension memiliki pubspec dev-only dan menjadi anggota
workspace, sehingga `dart test` dan `flutter analyze` memakai dependency yang
konsisten.
