# Keystore and Keychain

- iOS Keychain data can survive after the app is deleted. `FirstRunWipe` clears
  leftovers from an old installation on the first start.
- The Android Keystore can lose keys after a restore or a change to the device
  credentials; the app must be ready to accept a `Failure`.
- The web uses encrypted IndexedDB and is not as strong as native
  Keychain/Keystore.
- `android.allow_backup=false` prevents encrypted data from being included in
  backups.
