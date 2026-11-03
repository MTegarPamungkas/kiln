# Firebase Emulator Suite

The development flavor uses emulators by default so it does not touch production
data. Staging and production are never pointed at emulators.

## Ports

| Service | Port |
| --- | --- |
| Authentication | 9099 |
| Firestore | 8080 |
| Cloud Storage | 9199 |

These values come from `FirebaseEmulatorPorts` and can be changed via
`FirebaseConfig.copyWith`.

## Running the emulators

```bash
firebase init emulators
firebase emulators:start --import=./.emulator-data --export-on-exit
```

`FirebaseEmulator.configure` is called from `FirebaseModule.ready` before other
services are used, so `useAuthEmulator`, `useFirestoreEmulator`, and
`useStorageEmulator` happen before the first SDK call.

## Configuration

```dart
FirebaseModule(
  flavor: AppFlavor.development,
  config: FirebaseConfig.defaults.copyWith(emulatorHost: '10.0.2.2'),
  options: DefaultFirebaseOptions.currentPlatform,
)
```

Use `10.0.2.2` on the Android emulator. For a physical device, use the IP address
of the computer running the emulator and make sure the ports are open.

## Security rules in the emulator

The emulator uses the local `firestore.rules` and `storage.rules`. Copy the rules
from [security-rules.md](security-rules.md) and test the application flow before
deploying.
