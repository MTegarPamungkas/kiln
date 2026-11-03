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
