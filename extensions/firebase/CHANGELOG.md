# Changelog

## 0.2.1

- Add `FirebaseSupport` and initialize Firebase during bootstrap.
- Missing options are `notConfigured`; initialization or emulator/session
  errors are recorded as `unavailable` instead of failing startup.

## 0.2.0

- Defer Firebase SDK access in `FirebaseSessionBridge` until `ready()`, so
  `register()` no longer needs a default Firebase App. Apps no longer need to
  call `Firebase.initializeApp` before `KilnBootstrap.run`.
- `FirebaseSessionBridge` now takes a `users` stream factory instead of an
  eagerly evaluated stream.
- Document that explicit `FirebaseOptions` must include `storageBucket` for
  `FileStorage`.

## 0.1.0

- AuthRepository, SocialAuth, AccountManagement, and TokenProvider on top of
  Firebase Auth through a gateway that can be faked.
- Firestore RemoteDatabase with a RemoteQuery mapper, rejection of composite
  index combinations, and realtime watch.
- Cloud Storage FileStorage with upload progress.
- Session bridge to SessionController, emulator setup for the development
  flavor, typed configuration, FlutterFire warning hook, and setup
  documentation.
