import 'package:kiln_core/kiln_core.dart';

import 'firebase_app.dart';
import 'firebase_config.dart';

/// Initializes Firebase during bootstrap and reports a safe support state.
///
/// Missing options are `notConfigured`; an SDK initialization error is
/// `unavailable`. The initializer is idempotent, so `ready` can call it again.
final class FirebaseSupport {
  FirebaseSupport({
    required this.initializer,
    required this.config,
    required this.flavor,
  });

  final FirebaseAppInitializer initializer;
  final FirebaseConfig config;
  final AppFlavor flavor;
  SupportInfo? _last;

  Future<SupportInfo> check() async {
    final last = _last;
    if (last != null) {
      return last;
    }
    final info = await _probe();
    _last = info;
    return info;
  }

  void clear() => _last = null;

  Future<SupportInfo> _probe() async {
    try {
      await initializer.initialize();
      return SupportInfo.supported(
        details: <String, Object?>{
          'options_source': config.optionsSource.name,
          'emulator': config.shouldUseEmulator(flavor),
        },
      );
    } on Failure catch (failure) {
      return SupportInfo.unsupported(
        failure.kind == FailureKind.configuration
            ? SupportState.notConfigured
            : SupportState.unavailable,
        message: failure.message,
        details: <String, Object?>{'code': failure.code.value},
      );
    } on Object catch (error) {
      return SupportInfo.unsupported(
        SupportState.unavailable,
        message: 'Firebase could not be initialized: $error',
        details: <String, Object?>{'error': '$error'},
      );
    }
  }
}
