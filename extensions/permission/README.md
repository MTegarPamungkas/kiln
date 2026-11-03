# permission

An implementation of `Permissions` from `kiln_core` on top of
`permission_handler`.

- Only the kind selected at install is active; other kinds produce
  `Failure(configuration)`.
- Status is cached and the cache is cleared when the app returns from settings.
- `PermissionFlow` runs status, rationale, request, and directions to settings
  for permanently denied permissions.
- `PermissionGroup` requests several permissions at once.
- `PermissionGate`, `PermissionRationaleDialog`, and `OpenSettingsDialog` are
  available for the UI.

Native notes: Android manifest entries and the iOS Info.plist must be adjusted
to match the selected kind. `permission_handler` does not add native entries
automatically.

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
