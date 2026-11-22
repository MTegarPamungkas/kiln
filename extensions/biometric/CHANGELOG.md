# Changelog

## 0.1.1

- The module orders itself after secure storage, so protected storage is
  registered when both extensions are installed.
- `BiometricProtectedStorage.readAll` now requires the same biometric
  authentication as `read`: one prompt gates the whole bulk read.
- The manifest declares the optional `secure_storage` dependency the module
  already uses, so bootstrap orders them correctly.
- `Biometric.availability` probes biometric hardware with
  `canCheckBiometrics` and only falls back to `isDeviceSupported`, so a profile
  with hardware but no enrollment reports `notEnrolled`/`permissionDenied`
  instead of claiming the device has no sensor.

## 0.1.0

- Initial release.
