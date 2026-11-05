# Firebase setup

1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. Register the Android, iOS, macOS, and web applications you use.
3. In Authentication, enable the Email/Password, Google, and Apple providers as
   needed.
4. Create a Firestore database in production mode and a Cloud Storage bucket.
5. Install the FlutterFire CLI and run `flutterfire configure`:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

6. Pass the generated result to the module:

   ```dart
   FirebaseModule(
     flavor: AppFlavor.production,
     options: DefaultFirebaseOptions.currentPlatform,
   )
   ```

## Google Sign-In

- Android: add the debug and release SHA-1 and SHA-256 fingerprints to the
  Android application in the Firebase Console, then download
  `google-services.json` again.
- iOS/macOS: add the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` as a
  URL scheme in Xcode.
- Web: add the application domain to Authorized domains.

The `google_sign_in` package is not needed: `FirebaseSocialAuth` uses
`FirebaseAuth.signInWithProvider`, which runs the native flow.

## Apple Sign-In

- Enable the Apple provider in the Firebase Console.
- Add the Sign in with Apple capability to the iOS/macOS target.
- Fill in the Service ID and key in the Firebase Console when using web or
  Android.

## Emulator configuration

The development flavor uses emulators by default. See
[emulators.md](emulators.md) for ports and how to run them.
