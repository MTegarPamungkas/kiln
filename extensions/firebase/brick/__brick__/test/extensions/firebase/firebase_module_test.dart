import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_account_management.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_app.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_auth_repository.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_config.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_emulator.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_file_storage.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_gateway.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_id_token_provider.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_module.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_session_bridge.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_storage_gateway.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_support.dart';
import 'package:{{app_name}}/extensions/firebase/firestore_gateway.dart';
import 'package:{{app_name}}/extensions/firebase/firestore_remote_database.dart';

import 'firebase_contract_test.dart';

void main() {
  test('register exposes every Firebase contract', () {
    final registry = _registry();
    final module = _module();

    module.register(registry);

    expect(registry.read<FirebaseConfig>(), isA<FirebaseConfig>());
    expect(registry.read<FirebaseSupport>(), isA<FirebaseSupport>());
    expect(registry.read<AuthRepository>(), isA<FirebaseAuthRepository>());
    expect(registry.read<SocialAuth>(), isA<FirebaseSocialAuth>());
    expect(
      registry.read<AccountManagement>(),
      isA<FirebaseAccountManagement>(),
    );
    expect(registry.read<TokenProvider>(), isA<FirebaseIdTokenProvider>());
    expect(registry.read<RemoteDatabase>(), isA<FirestoreRemoteDatabase>());
    expect(registry.read<FileStorage>(), isA<FirebaseFileStorage>());
    expect(registry.read<FirebaseAuthGateway>(), isA<FirebaseAuthGateway>());
    expect(registry.read<FirestoreGateway>(), isA<FirestoreGateway>());
    expect(
      registry.read<FirebaseStorageGateway>(),
      isA<FirebaseStorageGateway>(),
    );
    expect(registry.read<FirebaseEmulator>(), isA<FirebaseEmulator>());
    expect(
      registry.read<FirebaseSessionBridge>(),
      isA<FirebaseSessionBridge>(),
    );
  });

  test('register does not read Firebase Auth before ready', () {
    final registry = _registry();
    final auth = _CountingAuthGateway();
    final module = FirebaseModule(
      authGateway: auth,
      firestoreGateway: InMemoryFirestoreGateway(),
      storageGateway: InMemoryFirebaseStorageGateway(),
      initializer: _FakeInitializer(),
    );

    module.register(registry);

    expect(auth.authStateChangesReads, 0);
  });

  test(
    'ready initializes Firebase, emulators, and the session bridge',
    () async {
      final registry = _registry();
      final auth = FakeFirebaseAuthGateway();
      final firestore = InMemoryFirestoreGateway();
      final storage = InMemoryFirebaseStorageGateway();
      final initializer = _FakeInitializer();
      final module = FirebaseModule(
        flavor: AppFlavor.development,
        authGateway: auth,
        firestoreGateway: firestore,
        storageGateway: storage,
        initializer: initializer,
      );

      module.register(registry);
      await module.ready(registry);
      auth.emit(const FirebaseUser(uid: 'ready-user', email: 'ready@kiln.dev'));

      expect(initializer.calls, 1);
      expect(auth.lastEmulatorHost, 'localhost');
      expect(auth.lastEmulatorPort, 9099);
      expect(firestore.emulatorPort, 8080);
      expect(storage.emulatorPort, 9199);
      expect(
        registry.read<SessionController>().status,
        SessionStatus.authenticated,
      );
      expect(registry.read<FirebaseSessionBridge>().isRunning, isTrue);

      await module.dispose();
      expect(registry.read<FirebaseSessionBridge>().isRunning, isFalse);
    },
  );

  test('production flavor never points the SDKs at an emulator', () async {
    final registry = _registry();
    final auth = FakeFirebaseAuthGateway();
    final firestore = InMemoryFirestoreGateway();
    final storage = InMemoryFirebaseStorageGateway();
    final module = FirebaseModule(
      authGateway: auth,
      firestoreGateway: firestore,
      storageGateway: storage,
      initializer: _FakeInitializer(),
    );

    module.register(registry);
    await module.ready(registry);

    expect(auth.lastEmulatorHost, isNull);
    expect(firestore.emulatorHost, isNull);
    expect(storage.emulatorHost, isNull);
    await module.dispose();
  });
}

Registry _registry() {
  final registry = GetItRegistry();
  registry.registerSingleton<SessionController>(SessionController());
  return registry;
}

FirebaseModule _module() {
  return FirebaseModule(
    authGateway: FakeFirebaseAuthGateway(),
    firestoreGateway: InMemoryFirestoreGateway(),
    storageGateway: InMemoryFirebaseStorageGateway(),
    initializer: _FakeInitializer(),
  );
}

final class _FakeInitializer implements FirebaseAppInitializer {
  int calls = 0;

  @override
  Future<void> initialize() async {
    calls += 1;
  }
}

final class _CountingAuthGateway implements FirebaseAuthGateway {
  int authStateChangesReads = 0;

  @override
  Stream<FirebaseUser?> get authStateChanges {
    authStateChangesReads += 1;
    return const Stream<FirebaseUser?>.empty();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
