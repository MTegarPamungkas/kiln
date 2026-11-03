# Firebase Emulator Suite

Flavor development memakai emulator secara default agar tidak menyentuh data
production. Staging dan production tidak pernah diarahkan ke emulator.

## Port

| Layanan | Port |
| --- | --- |
| Authentication | 9099 |
| Firestore | 8080 |
| Cloud Storage | 9199 |

Nilai ini berasal dari `FirebaseEmulatorPorts` dan dapat diubah lewat
`FirebaseConfig.copyWith`.

## Menjalankan emulator

```bash
firebase init emulators
firebase emulators:start --import=./.emulator-data --export-on-exit
```

`FirebaseEmulator.configure` dipanggil dari `FirebaseModule.ready` sebelum
layanan lain dipakai, sehingga `useAuthEmulator`, `useFirestoreEmulator`, dan
`useStorageEmulator` terjadi sebelum panggilan SDK pertama.

## Konfigurasi

```dart
FirebaseModule(
  flavor: AppFlavor.development,
  config: FirebaseConfig.defaults.copyWith(emulatorHost: '10.0.2.2'),
  options: DefaultFirebaseOptions.currentPlatform,
)
```

Gunakan `10.0.2.2` pada emulator Android. Untuk perangkat fisik, gunakan IP
komputer yang menjalankan emulator dan pastikan port terbuka.

## Aturan keamanan di emulator

Emulator memakai `firestore.rules` dan `storage.rules` lokal. Salin aturan dari
[security-rules.md](security-rules.md) lalu uji alur aplikasi sebelum deploy.
