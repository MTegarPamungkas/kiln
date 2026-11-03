import 'package:firebase_core/firebase_core.dart';
import 'package:kiln_core/kiln_core.dart';

import 'firebase_account_management.dart';
import 'firebase_app.dart';
import 'firebase_auth_repository.dart';
import 'firebase_config.dart';
import 'firebase_emulator.dart';
import 'firebase_failure_mapper.dart';
import 'firebase_file_storage.dart';
import 'firebase_gateway.dart';
import 'firebase_id_token_provider.dart';
import 'firebase_session_bridge.dart';
import 'firebase_storage_gateway.dart';
import 'firebase_support.dart';
import 'firestore_gateway.dart';
import 'firestore_remote_database.dart';
import 'firestore_query_mapper.dart';

/// Registers the Firebase implementations of the core contracts.
final class FirebaseModule extends KilnModule {
  FirebaseModule({
    this.config = FirebaseConfig.defaults,
    this.flavor = AppFlavor.production,
    this.options,
    this.authGateway,
    this.firestoreGateway,
    this.storageGateway,
    this.initializer,
  });

  final FirebaseConfig config;
  final AppFlavor flavor;
  final FirebaseOptions? options;

  /// Optional gateways used by tests and by applications that preconfigure the
  /// SDK. Production wiring uses the `Sdk*` gateways.
  final FirebaseAuthGateway? authGateway;
  final FirestoreGateway? firestoreGateway;
  final FirebaseStorageGateway? storageGateway;
  final FirebaseAppInitializer? initializer;

  FirebaseSessionBridge? _bridge;
  FirebaseAppInitializer? _initializer;

  @override
  String get id => 'firebase';

  @override
  Set<String> get provides => const <String>{
    'auth',
    'social_auth',
    'remote_database',
    'file_storage',
  };

  @override
  void register(Registry registry) {
    final auth = authGateway ?? SdkFirebaseAuthGateway();
    final firestore = firestoreGateway ?? SdkFirestoreGateway();
    final storage = storageGateway ?? SdkFirebaseStorageGateway();
    const queryMapper = FirestoreQueryMapper();

    final repository = FirebaseAuthRepository(
      gateway: auth,
      failureMapper: mapFirebaseError,
    );
    final social = FirebaseSocialAuth(
      gateway: auth,
      failureMapper: mapFirebaseError,
    );
    final account = FirebaseAccountManagement(
      gateway: auth,
      failureMapper: mapFirebaseError,
    );
    final tokens = FirebaseIdTokenProvider(
      gateway: auth,
      failureMapper: mapFirebaseError,
    );
    final database = FirestoreRemoteDatabase(
      gateway: firestore,
      queryMapper: queryMapper,
      failureMapper: mapFirebaseError,
    );
    final files = FirebaseFileStorage(
      gateway: storage,
      failureMapper: mapFirebaseError,
    );
    final emulator = FirebaseEmulator(
      config: config,
      auth: auth,
      firestore: firestore,
      storage: storage,
    );
    final bridge = FirebaseSessionBridge(
      controller: registry.read<SessionController>(),
      // Keep register() free of SDK access: ready() initializes Firebase
      // before the bridge resolves this stream.
      users: () => auth.authStateChanges,
    );
    _bridge = bridge;
    final appInitializer =
        initializer ?? FirebaseBootstrap(config: config, options: options);
    _initializer = appInitializer;

    registry
      ..registerSingleton<FirebaseConfig>(config)
      ..registerSingleton<FirebaseSupport>(
        FirebaseSupport(
          initializer: appInitializer,
          config: config,
          flavor: flavor,
        ),
      )
      ..registerSingleton<FirebaseAuthGateway>(auth)
      ..registerSingleton<FirestoreGateway>(firestore)
      ..registerSingleton<FirebaseStorageGateway>(storage)
      ..registerSingleton<AuthRepository>(repository)
      ..registerSingleton<SocialAuth>(social)
      ..registerSingleton<AccountManagement>(account)
      ..registerSingleton<TokenProvider>(tokens)
      ..registerSingleton<RemoteDatabase>(database)
      ..registerSingleton<FileStorage>(files)
      ..registerSingleton<FirebaseEmulator>(emulator)
      ..registerSingleton<FirebaseSessionBridge>(bridge);
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<FirebaseSupport>().check();
  }

  @override
  Future<void> ready(Registry registry) async {
    final supportRegistry = registry.readOrNull<SupportRegistry>();
    final appInitializer =
        _initializer ?? FirebaseBootstrap(config: config, options: options);
    try {
      await appInitializer.initialize();
      await registry.read<FirebaseEmulator>().configure(flavor);
      registry.read<FirebaseSessionBridge>().start();
    } on Object catch (error) {
      supportRegistry?.record(
        id,
        SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'Firebase could not finish starting: $error',
          details: <String, Object?>{'error': '$error'},
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    final bridge = _bridge;
    _bridge = null;
    await bridge?.dispose();
  }
}
