# Changelog

## 0.2.0

- Defer Firebase SDK access in `FirebaseSessionBridge` until `ready()`, so
  `register()` no longer needs a default Firebase App. Apps no longer need to
  call `Firebase.initializeApp` before `KilnBootstrap.run`.
- `FirebaseSessionBridge` now takes a `users` stream factory instead of an
  eagerly evaluated stream.
- Document that explicit `FirebaseOptions` must include `storageBucket` for
  `FileStorage`.

## 0.1.0

- AuthRepository, SocialAuth, AccountManagement, dan TokenProvider di atas
  Firebase Auth lewat gateway yang bisa di-fake.
- Firestore RemoteDatabase dengan mapper RemoteQuery, penolakan kombinasi
  indeks komposit, dan watch realtime.
- Cloud Storage FileStorage dengan progress unggah.
- Session bridge ke SessionController, setup emulator flavor development,
  konfigurasi bertipe, hook peringatan FlutterFire, serta dokumentasi setup.
