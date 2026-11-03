# Changelog

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
