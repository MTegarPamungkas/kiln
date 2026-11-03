# App lock

`AppLock` mengunci aplikasi ketika user meninggalkan aplikasi lebih lama dari
`grace_seconds`.

Alurnya:

1. `AppLockScope` menerima lifecycle `paused` dan mencatat waktunya.
2. Saat `resumed`, selisih waktu dibandingkan dengan masa tenggang.
3. Bila melewati batas, overlay kunci tampil menutupi seluruh aplikasi.
4. Tombol buka meminta biometrik lewat `BiometricGate`.
5. Bila autentikasi berhasil, overlay hilang; bila gagal, overlay tetap.

```dart
AppLockScope(
  appLock: registry.read<AppLock>(),
  child: const MyApp(),
)
```

Module biometric menambahkan wrapper ini ke slot `app.wrappers`, jadi aplikasi
hasil generate tidak perlu mengedit `app_shell.dart`. Wrapper berjalan di luar
`MaterialApp`; overlay memakai `Directionality` dan `Material` sendiri agar
tetap valid.

## Masa tenggang

Masa tenggang mencegah kunci muncul saat user hanya membuka kamera atau dialog
izin sistem. Nilai 0 mengunci setiap kali aplikasi kembali dari latar.
