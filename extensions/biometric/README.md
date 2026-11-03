# biometric

Biometrik lokal, kunci aplikasi, dan penyimpanan rahasia yang dilindungi.

- `Biometric` membungkus `canAuthenticate`, `availableBiometrics`, dan
  `authenticate` lewat gateway yang bisa di-fake.
- `BiometricAvailability` membedakan available, notEnrolled, noHardware, dan
  unsupportedPlatform.
- `BiometricGate` menjalankan aksi setelah autentikasi dan menyimpan masa
  tenggang memakai `Clock`.
- `AppLock` mengunci aplikasi setelah pause melewati batas;
  `AppLockScope` menutup layar dan menyediakan tombol buka.
- `BiometricProtectedStorage` meminta autentikasi sebelum `read`.

Panduan kunci aplikasi: [docs/app-lock.md](docs/app-lock.md). Persyaratan
platform: [docs/platform-requirements.md](docs/platform-requirements.md).
