# flavors

Nilai flavor Dart, entry point per flavor, dan konfigurasi launch VS Code.

- `AppFlavors` mendefinisikan development, staging, dan production.
- `main_development.dart`, `main_staging.dart`, dan `main_production.dart`
  menjalankan aplikasi dengan flavor masing-masing.
- `FlavorsModule` menambahkan `FlavorBanner` ke slot `app.wrappers`.
- `ReleaseGuard` memperingatkan build release yang memakai flavor
  non-production.
- `FlavorX.valueFor` memilih nilai per flavor.

Flavor di sini adalah nilai Dart, bukan product flavor native Android/iOS.
Lihat [docs/native-flavors-not-included.md](docs/native-flavors-not-included.md).
