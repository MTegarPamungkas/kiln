# Changelog

## 0.1.2

- Add `SupportInfo`, `SupportState`, and `SupportRegistry` so extensions can
  report platform and device support without app-side probing.
- Add `KilnModule.support`; bootstrap records it and skips `ready` when the
  extension is not supported.
- Add `FailureCode.unsupportedPlatform` and `FailureCode.unsupportedDevice`,
  plus `PermissionStatus.unsupported`.

## 0.1.1

- Add `KilnModule.platforms` and skip unsupported modules in
  `KilnBootstrap`; expose `currentPlatform`.

## 0.1.0

- Initial contracts, errors, registry runtime, slot, session, privacy, and
  utility layer.
