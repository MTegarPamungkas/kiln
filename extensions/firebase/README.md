# firebase

Implementation of the `kiln_core` contracts on top of Firebase:

- `AuthRepository` in `FirebaseAuthRepository` through the `FirebaseAuthGateway` gateway.
- `SocialAuth` in `FirebaseSocialAuth` uses Firebase Auth `signInWithProvider`
  for Google and Apple.
- `AccountManagement` for password reset, email verification, and profile updates.
- `TokenProvider` in `FirebaseIdTokenProvider` uses `getIdToken`, including a
  forced refresh when a `401` is received.
- `RemoteDatabase` in `FirestoreRemoteDatabase` with typed queries and realtime
  `watch`.
- `FileStorage` in `FirebaseFileStorage` with upload progress.
- `FirebaseSessionBridge` forwards `authStateChanges` to `SessionController`.

## Installation

```bash
kiln ext add firebase
```

Then complete the manual `firebase_flutterfire_configure` step:
see [docs/flutterfire-configure.md](docs/flutterfire-configure.md).

## Usage

```dart
final registry = await KilnBootstrap.run(
  modules: [
    FirebaseModule(
      flavor: AppFlavor.development,
      options: DefaultFirebaseOptions.currentPlatform,
    ),
  ],
  capabilities: {'auth', 'social_auth', 'remote_database', 'file_storage'},
);

final auth = registry.read<AuthRepository>();
await auth.signIn(email: 'user@kiln.dev', password: 'password123');

final database = registry.read<RemoteDatabase>();
await database.create('tasks', {'title': 'Learn Kiln', 'done': false});
```

`FirebaseOptions` must be provided to `FirebaseModule`. If you use the output of
the FlutterFire CLI, pass `DefaultFirebaseOptions.currentPlatform`. If the build
supplies its own configuration, pass the matching `FirebaseOptions` and change
the `options_source` prompt to `explicit`.

For `FileStorage`, those options must include `storageBucket`
(for example `project-id.appspot.com`). Without a bucket,
`FirebaseStorage.instance` fails with `firebase_storage/no-bucket`.

`FirebaseModule` initializes Firebase in `ready()`, so the app does not need to
call `Firebase.initializeApp` before `KilnBootstrap.run`.

## Important behavior

- All SDK access sits behind `FirebaseAuthGateway`, `FirestoreGateway`,
  and `FirebaseStorageGateway`, so tests do not need a Firebase app.
- Query combinations that require a composite index are rejected up front with
  `Failure(validation.unsupported_value)` instead of being left to fail in the
  SDK.
- `RemoteQuery.offset` is translated into a `startAfterDocument` cursor
  because Cloud Firestore 7 no longer provides `Query.offset`. The results and
  read cost are equivalent to a Firestore offset.
- The `development` flavor points at the Firebase Emulator Suite by default.
  Staging and production never point at localhost.
- The Mason hook only warns when `flutterfire` or
  `lib/firebase_options.dart` is not available; installation never fails.

Other documentation: [setup](docs/firebase-setup.md),
[emulator](docs/emulators.md), [security rules](docs/security-rules.md).

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
