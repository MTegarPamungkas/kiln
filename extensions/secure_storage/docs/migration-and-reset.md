# Migration and reset

Secure storage is durable and platform-specific. Treat "no value" and "cannot
decrypt" as different states and give the app a path back to a signed-out state.

## Namespaces

`NamespacedSecureStorage` prefixes keys with an owner name:

```dart
final tokens = NamespacedSecureStorage(
  inner: registry.read<SecureStorage>(),
  namespace: 'auth',
);

await tokens.write('access_token', token);
```

`readAll()` and `clear()` only see that owner's keys, so two extensions can use
the same key name without clobbering each other. Keep the namespace stable: a
rename makes existing secrets unreachable.

## Reinstall and first-run wipe

iOS Keychain items can survive an uninstall. `FirstRunWipe` deletes leftover
entries once, on the first launch after install, guarded by a marker key in the
preference store. Run it only on iOS during bootstrap; Android and web do not
need it.

## Android restore and lock-screen changes

Keystore keys can be invalidated by a device restore or a lock-screen credential
change. Decryption then fails. The app should:

1. Treat the read as `Failure(secure_storage.*)`, not as a missing token.
2. Clear the namespace (`clear()`), sign out locally, and ask the user to sign in
   again.
3. Never fall back to a plain `Storage` value for a secret.

## Web

Web secure storage uses encrypted IndexedDB and the key lives in browser
storage. It is weaker than Keychain/Keystore; use it for convenience, not for
server-side secrets or high-value credentials.

## Backups

The extension sets `android.allow_backup=false` so encrypted preferences are not
restored with app backups. Keep that setting unless you have a deliberate
encrypted-backup design.

## Testing

Use `InMemorySecureStorage` for happy paths and a failing fake for read/write
errors. Test the wipe marker, namespace isolation, and the app's recovery path
after an unreadable value.
