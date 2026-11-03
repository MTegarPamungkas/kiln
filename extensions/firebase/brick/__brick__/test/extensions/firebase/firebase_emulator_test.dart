import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_config.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_emulator.dart';

import 'firebase_contract_test.dart';

void main() {
  test('development redirects auth, firestore, and storage', () async {
    final auth = FakeFirebaseAuthGateway();
    final firestore = InMemoryFirestoreGateway();
    final storage = InMemoryFirebaseStorageGateway();
    final emulator = FirebaseEmulator(
      config: const FirebaseConfig(emulatorHost: '127.0.0.1'),
      auth: auth,
      firestore: firestore,
      storage: storage,
    );

    final enabled = await emulator.configure(AppFlavor.development);

    expect(enabled, isTrue);
    expect(emulator.isConfigured, isTrue);
    expect(auth.lastEmulatorHost, '127.0.0.1');
    expect(auth.lastEmulatorPort, 9099);
    expect(firestore.emulatorHost, '127.0.0.1');
    expect(firestore.emulatorPort, 8080);
    expect(storage.emulatorHost, '127.0.0.1');
    expect(storage.emulatorPort, 9199);
  });

  test('staging and production are never redirected', () async {
    final auth = FakeFirebaseAuthGateway();
    final firestore = InMemoryFirestoreGateway();
    final storage = InMemoryFirebaseStorageGateway();
    final emulator = FirebaseEmulator(
      config: FirebaseConfig.defaults,
      auth: auth,
      firestore: firestore,
      storage: storage,
    );

    expect(await emulator.configure(AppFlavor.staging), isFalse);
    expect(await emulator.configure(AppFlavor.production), isFalse);

    expect(emulator.isConfigured, isFalse);
    expect(auth.lastEmulatorHost, isNull);
    expect(firestore.emulatorHost, isNull);
    expect(storage.emulatorHost, isNull);
  });

  test('configuring twice does not reconnect the emulators', () async {
    final auth = FakeFirebaseAuthGateway();
    final firestore = InMemoryFirestoreGateway();
    final storage = InMemoryFirebaseStorageGateway();
    final emulator = FirebaseEmulator(
      config: FirebaseConfig.defaults,
      auth: auth,
      firestore: firestore,
      storage: storage,
    );

    expect(await emulator.configure(AppFlavor.development), isTrue);
    expect(await emulator.configure(AppFlavor.development), isTrue);

    expect(auth.emulatorCalls, 1);
  });
}
