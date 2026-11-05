import 'package:kiln_core/kiln_core.dart';

import 'firebase_config.dart';
import 'firebase_gateway.dart';
import 'firebase_storage_gateway.dart';
import 'firestore_gateway.dart';

/// Redirects Firebase Auth, Firestore, and Storage to the local emulators.
///
/// Emulators must be configured before the first SDK call, so the module calls
/// this from `ready()` and the development flavor is the only one redirected.
final class FirebaseEmulator {
  FirebaseEmulator({
    required this.config,
    required this.auth,
    required this.firestore,
    required this.storage,
  });

  final FirebaseConfig config;
  final FirebaseAuthGateway auth;
  final FirestoreGateway firestore;
  final FirebaseStorageGateway storage;

  bool _configured = false;

  bool get isConfigured => _configured;

  /// Returns whether the emulators are active after this call.
  Future<bool> configure(AppFlavor flavor) async {
    if (!config.shouldUseEmulator(flavor) || _configured) {
      return _configured;
    }
    final host = config.emulatorHost;
    await auth.useEmulator(host, config.ports.auth);
    firestore.useEmulator(host, config.ports.firestore);
    await storage.useEmulator(host, config.ports.storage);
    _configured = true;
    return true;
  }
}
