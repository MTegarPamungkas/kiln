# secure_storage

Implementation of `SecureStorage` from `kiln_core` on top of Keychain/Keystore.

Brick contents:

- a `FlutterSecureStorage` gateway that can be faked,
- Android/iOS/Web configuration,
- per-namespace prefix,
- a `SecureTokenStore` that satisfies `TokenProvider`,
- `FirstRunWipe` for leftover iOS Keychain entries,
- `SecureStorageHealthCheck` for a write-read-delete probe.

This extension sets `android.allow_backup=false` so that encrypted data is not
carried over by backups across installations.

## Gate

```dart
final token = await gate.readSecure('access_token');   // Result<String?>
await gate.writeSecure('access_token', token);        // Result<void>
final all = await gate.readAllSecure();               // Result<Map<String, String>>
await gate.clearSecure();                             // Result<void>
await gate.deleteSecure('access_token');              // Result<void>
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
