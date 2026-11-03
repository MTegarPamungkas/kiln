# firebase

Implementasi kontrak `kiln_core` di atas Firebase:

- `AuthRepository` di `FirebaseAuthRepository` lewat gateway `FirebaseAuthGateway`.
- `SocialAuth` di `FirebaseSocialAuth` memakai `signInWithProvider` Firebase Auth
  untuk Google dan Apple.
- `AccountManagement` untuk reset password, verifikasi email, dan ubah profil.
- `TokenProvider` di `FirebaseIdTokenProvider` memakai `getIdToken`, termasuk
  refresh paksa saat menerima `401`.
- `RemoteDatabase` di `FirestoreRemoteDatabase` dengan query bertipe dan
  `watch` realtime.
- `FileStorage` di `FirebaseFileStorage` dengan progress unggah.
- `FirebaseSessionBridge` meneruskan `authStateChanges` ke `SessionController`.

## Pemasangan

```bash
kiln ext add firebase
```

Lalu selesaikan langkah manual `firebase_flutterfire_configure`:
lihat [docs/flutterfire-configure.md](docs/flutterfire-configure.md).

## Pemakaian

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
await database.create('tasks', {'title': 'Belajar Kiln', 'done': false});
```

`FirebaseOptions` wajib diberikan ke `FirebaseModule`. Bila memakai output
FlutterFire CLI, teruskan `DefaultFirebaseOptions.currentPlatform`. Bila build
mengisi konfigurasi sendiri, teruskan `FirebaseOptions` yang sesuai dan ubah
prompt `options_source` menjadi `explicit`.

Untuk `FileStorage`, options tersebut harus memuat `storageBucket`
(misalnya `project-id.appspot.com`). Tanpa bucket, `FirebaseStorage.instance`
gagal dengan `firebase_storage/no-bucket`.

`FirebaseModule` menginisialisasi Firebase di `ready()`, jadi aplikasi tidak
perlu memanggil `Firebase.initializeApp` sebelum `KilnBootstrap.run`.

## Perilaku penting

- Semua akses SDK berada di balik `FirebaseAuthGateway`, `FirestoreGateway`,
  dan `FirebaseStorageGateway`, sehingga test tidak butuh aplikasi Firebase.
- Kombinasi query yang membutuhkan indeks komposit ditolak lebih awal dengan
  `Failure(validation.unsupported_value)`, bukan dibiarkan gagal di SDK.
- `RemoteQuery.offset` diterjemahkan menjadi cursor `startAfterDocument`
  karena Cloud Firestore 7 tidak lagi menyediakan `Query.offset`. Hasil dan
  biaya bacanya setara dengan offset Firestore.
- Flavor `development` diarahkan ke Firebase Emulator Suite secara default.
  Staging dan production tidak pernah diarahkan ke localhost.
- Hook Mason hanya memberi peringatan bila `flutterfire` atau
  `lib/firebase_options.dart` belum tersedia; instalasi tidak pernah gagal.

Dokumentasi lain: [setup](docs/firebase-setup.md),
[emulator](docs/emulators.md), [security rules](docs/security-rules.md).
