# Changelog

## 0.3.0

- Register `PermissionFlow` and `PermissionGroup` and add a `gate_permission.dart`
  so batch requests (`ensurePermissions`) and `openPermissionSettings` are
  reachable as one-call `Result` verbs.
- `DevicePermissions` now maps unexpected platform errors to a
  `permission.denied` `Failure` through the shared mapper.
- Remove the unused `rationaleTitle`/`rationaleMessage` config fields; rationale
  copy belongs to the application.

## 0.2.0

- Removed `PermissionGate` and the permission dialogs. Applications request permissions through `Permissions` and render their own rationale UI.

## 0.1.1

- Add `PermissionSupport` and report platform/device support through
  `SupportRegistry`.
- `Permissions.status` and `Permissions.ensure` return
  `PermissionStatus.unsupported` instead of throwing when a kind does not
  exist on the current platform or device.

## 0.1.0

- Initial permission guard, cache, flow, group, resume observer, and widgets.
