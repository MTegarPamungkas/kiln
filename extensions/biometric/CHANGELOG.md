# Changelog

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
