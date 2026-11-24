# Changelog

## 0.1.3

- Update Firebase dependency constraints (`cloud_firestore` `^7.2.0`, `firebase_auth` `^7.1.0`, `firebase_core` `^5.2.0`, `firebase_storage` `^14.1.0`).

## 0.1.2

- Repack archive with deterministic cross-OS gzip and without root `test/`.

## 0.1.1

- `ready()` no longer configures the emulator or starts the session bridge
  after the module was disposed during `Firebase.initializeApp`, and the bridge
  ignores a late `start()`.
- Declares the `token_provider` and `account_management` capabilities the module already registers, so `kiln doctor` capability coverage and backend-swap guidance see them.
- The runtime module now provides those capabilities and mirrors the manifest's platform list.
- `FileStorage.url` rejects a requested `expiresIn` with a typed unsupported failure instead of returning a permanent download URL.
- `FirebaseSocialAuth` marks its Firebase ID token as a backend token and keeps it separate from provider access tokens.

## 0.1.0

- Initial release.
