# Keystore and Keychain

Native secure storage is durable but has platform sharp edges. `secure_storage`
absorbs them so the app only sees `Result`s.

## iOS

Keychain items can survive an app uninstall. A fresh install may therefore read
stale secrets left by a previous one. `FirstRunWipe` clears that leftover data on
the very first launch after install (a marker key guards it so it runs once).

## Android

The Keystore can drop keys after a device restore or a change to the lock-screen
credentials. Decryption then fails, so reads must be able to return a `Failure`
and the app must handle a missing secret (re-authenticate, re-provision) rather
than assume the value is there.

## Web

There is no real keystore; the web backend uses encrypted IndexedDB, which is
weaker than Keychain/Keystore because the key lives in browser storage. Treat the
web as convenience, not high-value secret storage.

## Backups

Set `android.allow_backup=false` (the manifest already does) so encrypted
preferences are not pulled into Android cloud backups, which would let a device
restore resurrect secrets outside the keystore.
