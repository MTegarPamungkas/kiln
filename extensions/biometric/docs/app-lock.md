# App lock

`AppLock` locks the application when the user leaves it for longer than
`grace_seconds`.

The flow:

1. `AppLockScope` receives the `paused` lifecycle event and records the time.
2. On `resumed`, the elapsed time is compared with the grace period.
3. If it exceeds the limit, a lock overlay appears covering the whole
   application.
4. The unlock button requests biometrics through `BiometricGate`.
5. If authentication succeeds, the overlay disappears; if it fails, the overlay
   stays.

```dart
AppLockScope(
  appLock: registry.read<AppLock>(),
  child: const MyApp(),
)
```

The biometric module adds this wrapper to the `app.wrappers` slot, so a generated
application does not need to edit `app_shell.dart`. The wrapper runs outside
`MaterialApp`; the overlay uses its own `Directionality` and `Material` so it
stays valid.

## Grace period

The grace period prevents the lock from appearing when the user merely opens the
camera or a system permission dialog. A value of 0 locks every time the
application returns from the background.
