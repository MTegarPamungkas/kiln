# Changelog

## 0.3.0

- Normalized every user-facing string to English: the `mapBiometricError`
  messages, `BiometricGate` and `BiometricProtectedStorage` failures, the
  default authentication `reason`, the `extension.yaml` prompt default and
  `NSFaceIDUsageDescription`, and the brick variable default. Applications can
  still localize the prompt by passing their own `reason`.

## 0.2.0

- The extension no longer registers a lock screen wrapper in `app.wrappers`.
  Applications own the lock UI, its copy, and its styling; the extension keeps
  `AppLock`, `BiometricGate`, availability, and protected storage.
- Removed the generated `AppLockScope` widget and its test. Add your own lock
  screen and forward the pause/resume events to `AppLock`.

## 0.1.4

- Report device support through the shared `SupportRegistry`.
- Return `support.unsupported_platform` and `support.unsupported_device`
  failures instead of a generic `unavailable` code.

## 0.1.3

- The app lock now checks device biometric availability at runtime. Devices
  without biometrics keep the app unlocked automatically.

## 0.1.2

- Declare supported platforms so `KilnBootstrap` skips biometric on web and
  other unsupported targets instead of blocking the whole project.

## 0.1.1

- Configuration test now renders the prompt answers instead of hardcoded
  defaults, so regenerated apps keep passing `flutter test`.

## 0.1.0

- Initial biometric facade, availability, gate, app lock, lock scope, and
  protected secure storage.
