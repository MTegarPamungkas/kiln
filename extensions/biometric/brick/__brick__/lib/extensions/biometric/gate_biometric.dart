import 'package:kiln_core/kiln_core.dart';

import 'app_lock.dart';
import 'biometric.dart';
import 'biometric_availability.dart';

/// Gate verbs for the biometric capability.
///
/// Augments the kiln_core [Gate] facade so the app toggles biometric lock
/// on/off and authenticates with a single call that returns a [Result]. The
/// app still owns the UI; the SDK only reports success, failure, and info.
extension GateBiometricX on Gate {
  Biometric get biometric => use<Biometric>();

  AppLock get appLock => use<AppLock>();

  Future<Result<BiometricAvailability>> biometricAvailability() =>
      call(biometric.availability);

  Future<Result<bool>> biometricAuthenticate({String? reason}) =>
      call(() => biometric.authenticate(reason: reason));

  /// Unlocks the app lock. `Ok(false)` means the biometric challenge failed.
  Future<Result<bool>> biometricUnlock() => call(appLock.unlock);
}
