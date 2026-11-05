# Biometric

```dart
final biometric = registry.read<Biometric>();

final availability = await biometric.availability();
if (availability == BiometricAvailability.available) {
  final ok = await biometric.authenticate();
}
```

## Status

| Status | Meaning |
| --- | --- |
| `available` | The device has hardware and at least one enrolled biometric |
| `notEnrolled` | Hardware is present, but no biometric is enrolled yet |
| `noHardware` | The device does not support it or the hardware is unavailable |
| `unsupportedPlatform` | Web or a platform other than Android, iOS, and macOS |

`authenticate()` returns false when the user fails the challenge, and throws a
`Failure` for cancellation, lockout, or hardware that is not ready.

## Guard

```dart
final gate = registry.read<BiometricGate>();
await gate.guard(() async {
  await deleteAccount();
});
```

The guard authenticates first, then allows other actions within the grace period
without a new dialog. `reset()` clears the grace period.

## Protected storage

`BiometricProtectedStorage` wraps `SecureStorage` and requires authentication on
every `read`. Writes do not require authentication so logout and cleanup can
still run.
