# biometric

Local biometrics, app lock, and protected secret storage.

- `Biometric` wraps `canAuthenticate`, `availableBiometrics`, and
  `authenticate` through a gateway that can be faked.
- `BiometricAvailability` distinguishes available, notEnrolled, noHardware, and
  unsupportedPlatform.
- `BiometricGate` runs an action after authentication and stores the grace
  period using `Clock`.
- `AppLock` locks the app after a pause exceeds the limit. The extension exposes
  the lock state only; the application renders its own lock screen.
- `BiometricProtectedStorage` requests authentication before `read`.

App lock guide: [docs/app-lock.md](docs/app-lock.md). Platform requirements:
[docs/platform-requirements.md](docs/platform-requirements.md).

## Gate

```dart
import 'package:my_app/extensions/biometric/gate_biometric.dart';

final availability = await gate.biometricAvailability();  // Result<BiometricAvailability>
final authenticated = await gate.biometricAuthenticate(); // Result<bool>
gate.appLock.lock();                // on
final unlock = await gate.biometricUnlock(); // off -> Result<bool>
```

The SDK toggles the lock state and reports success or failure; the app renders
its own lock screen.

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
