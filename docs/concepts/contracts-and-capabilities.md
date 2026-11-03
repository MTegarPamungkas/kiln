# Kontrak dan kapabilitas

`kiln_core` adalah satu-satunya package yang dikenal kode aplikasi dan semua
extension. Kontrak tersedia untuk:

HTTP (`HttpClient`, `HttpPipeline`, `HttpCache`), penyimpanan (`Storage`,
`SecureStorage`, `LocalDatabase`, `RemoteDatabase`, `FileStorage`), auth
(`AuthRepository`, `AccountManagement`, `SocialAuth`, `TokenProvider`),
platform (`NetworkMonitor`, `Permissions`, `Notifications`, `DeepLinks`,
`MediaPicker`), observability (`Analytics`, `CrashReporter`, `AppLogger`), dan
konfigurasi (`Env`, `AppFlavor`).

## Kapabilitas

Extension menyatakan `provides` dan `requires` dalam manifest. Resolver memilih
provider untuk setiap `requires`; extension tidak pernah menulis id extension
lain.

- Dua provider untuk capability yang sama = konflik.
- Capability hilang = konflik dengan saran install.
- `exclusive: true` menolak extension lain di kategori yang sama.
- `when` pada kontribusi slot hanya aktif bila capability tersebut ada.

Kode aplikasi membaca kontrak dari Registry:

```dart
final client = RegistryScope.read<HttpClient>(context);
```

Implementasi konkret seperti `DioClient` tidak diimpor aplikasi.
