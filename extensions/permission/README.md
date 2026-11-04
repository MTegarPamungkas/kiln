# permission

An implementation of `Permissions` from `kiln_core` on top of
`permission_handler`.

- Only the kind selected at install is active; other kinds produce
  `Failure(configuration)`.
- Status is cached and the cache is cleared when the app returns from settings.
- `PermissionFlow` runs status, rationale, request, and directions to settings
  for permanently denied permissions.
- `PermissionGroup` requests several permissions at once.
- Applications show rationale and settings prompts in their own UI; the
  extension returns status and flow results.

Native notes: Android manifest entries and the iOS Info.plist must be adjusted
to match the selected kind. `permission_handler` does not add native entries
automatically.

## Gate

```dart
final status = await gate.permissionStatus(PermissionKind.camera);
final result = await gate.requestPermission(PermissionKind.camera); // Result<PermissionStatus>
result.fold(
  ok: (status) => print('Granted: $status'),
  err: (failure) => print('${failure.code}: ${failure.details}'),
);
```

The SDK returns status and flow results; the app shows rationale and settings
prompts in its own UI.

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
