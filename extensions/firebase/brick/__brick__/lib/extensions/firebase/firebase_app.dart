import 'package:firebase_core/firebase_core.dart';
import 'package:kiln_core/kiln_core.dart';

import 'firebase_config.dart';

/// Creates the Firebase app before any Firebase service is used.
///
/// Pass `DefaultFirebaseOptions.currentPlatform` when the project uses the
/// generated `firebase_options.dart`, or hand-built `FirebaseOptions` when the
/// build injects configuration itself.
abstract interface class FirebaseAppInitializer {
  Future<void> initialize();
}

/// [FirebaseAppInitializer] backed by `Firebase.initializeApp`.
final class FirebaseBootstrap implements FirebaseAppInitializer {
  FirebaseBootstrap({this.config = FirebaseConfig.defaults, this.options});

  final FirebaseConfig config;
  final FirebaseOptions? options;

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      return;
    }
    final resolved = options;
    if (resolved == null) {
      throw Failure(
        code: FailureCode.configurationMissing,
        message:
            'FirebaseOptions belum diberikan ke FirebaseModule. Jalankan '
            'flutterfire configure lalu teruskan '
            'DefaultFirebaseOptions.currentPlatform.',
        kind: FailureKind.configuration,
        details: <String, Object?>{
          'source': config.optionsSource.name,
          'path': config.firebaseOptionsPath,
        },
      );
    }
    try {
      await Firebase.initializeApp(options: resolved);
      _initialized = true;
    } catch (error, stackTrace) {
      throw Failure(
        code: FailureCode.configurationInvalid,
        message: 'Firebase gagal diinisialisasi dengan options yang diberikan.',
        kind: FailureKind.configuration,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
