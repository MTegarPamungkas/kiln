import 'package:kiln_core/kiln_core.dart';

import 'biometric.dart';
import 'biometric_config.dart';

/// Requires authentication before running an action.
final class BiometricGate {
  BiometricGate({
    required this.biometric,
    this.config = BiometricConfig.defaults,
    this.clock = const SystemClock(),
  });

  final Biometric biometric;
  final BiometricConfig config;
  final Clock clock;
  DateTime? _lastSuccess;

  Future<T> guard<T>(Future<T> Function() action) async {
    await ensureAuthenticated();
    return action();
  }

  Future<void> ensureAuthenticated() async {
    final last = _lastSuccess;
    if (last != null && clock.now().difference(last) < config.gracePeriod) {
      return;
    }
    final authenticated = await biometric.authenticate();
    if (!authenticated) {
      throw const Failure(
        code: FailureCode.permissionDenied,
        message: 'Biometric authentication is required.',
        kind: FailureKind.permission,
      );
    }
    _lastSuccess = clock.now();
  }

  void reset() {
    _lastSuccess = null;
  }
}
