# Setup Firebase

1. Buat project di [Firebase Console](https://console.firebase.google.com).
2. Daftarkan aplikasi Android, iOS, macOS, dan web yang dipakai.
3. Di Authentication, aktifkan provider Email/Password, Google, dan Apple
   sesuai kebutuhan.
4. Buat database Firestore dalam mode production dan bucket Cloud Storage.
5. Pasang FlutterFire CLI lalu jalankan `flutterfire configure`:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

6. Teruskan hasil generate ke module:

   ```dart
   FirebaseModule(
     flavor: AppFlavor.production,
     options: DefaultFirebaseOptions.currentPlatform,
   )
   ```

## Google Sign-In

- Android: tambahkan SHA-1 dan SHA-256 fingerprint debug serta release ke
  aplikasi Android di Firebase Console, lalu unduh ulang `google-services.json`.
- iOS/macOS: tambahkan `REVERSED_CLIENT_ID` dari `GoogleService-Info.plist`
  sebagai URL scheme di Xcode.
- Web: tambahkan domain aplikasi ke Authorized domains.

Tidak perlu package `google_sign_in`: `FirebaseSocialAuth` memakai
`FirebaseAuth.signInWithProvider` yang menjalankan flow native.

## Apple Sign-In

- Aktifkan provider Apple di Firebase Console.
- Tambahkan capability Sign in with Apple pada target iOS/macOS.
- Isi Service ID dan key di Firebase Console bila memakai web atau Android.

## Konfigurasi emulator

Flavor development memakai emulator secara default. Lihat
[emulators.md](emulators.md) untuk port dan cara menjalankannya.
