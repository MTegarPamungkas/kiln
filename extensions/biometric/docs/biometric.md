# Biometric

```dart
final biometric = registry.read<Biometric>();

final availability = await biometric.availability();
if (availability == BiometricAvailability.available) {
  final ok = await biometric.authenticate();
}
```

## Status

| Status | Arti |
| --- | --- |
| `available` | Perangkat punya hardware dan minimal satu biometrik terdaftar |
| `notEnrolled` | Hardware ada, belum ada biometrik terdaftar |
| `noHardware` | Perangkat tidak mendukung atau hardware tidak tersedia |
| `unsupportedPlatform` | Web atau platform di luar Android, iOS, dan macOS |

`authenticate()` mengembalikan false bila user gagal tantangan, dan melempar
`Failure` untuk pembatalan, lockout, atau hardware yang tidak siap.

## Guard

```dart
final gate = registry.read<BiometricGate>();
await gate.guard(() async {
  await deleteAccount();
});
```

Guard mengautentikasi lebih dahulu, lalu mengizinkan aksi lain dalam masa
tenggang tanpa dialog baru. `reset()` menghapus masa tenggang.

## Penyimpanan terlindungi

`BiometricProtectedStorage` membungkus `SecureStorage` dan meminta autentikasi
pada setiap `read`. Penulisan tidak memerlukan autentikasi agar logout dan
pembersihan tetap bisa berjalan.
