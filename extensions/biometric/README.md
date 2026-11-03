# biometric

Local biometrics, app lock, and protected secret storage.

- `Biometric` wraps `canAuthenticate`, `availableBiometrics`, and
  `authenticate` through a gateway that can be faked.
- `BiometricAvailability` distinguishes available, notEnrolled, noHardware, and
  unsupportedPlatform.
- `BiometricGate` runs an action after authentication and stores the grace
  period using `Clock`.
- `AppLock` locks the app after a pause exceeds the limit;
  `AppLockScope` covers the screen and provides an unlock button.
- `BiometricProtectedStorage` requests authentication before `read`.

App lock guide: [docs/app-lock.md](docs/app-lock.md). Platform requirements:
[docs/platform-requirements.md](docs/platform-requirements.md).
