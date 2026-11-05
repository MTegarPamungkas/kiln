import 'package:local_auth/local_auth.dart';

import 'biometric_availability.dart';

/// Biometric platform access that can be faked in tests.
abstract interface class BiometricGateway {
  Future<bool> canCheckBiometrics();

  Future<bool> isDeviceSupported();

  Future<List<BiometricMethod>> availableBiometrics();

  Future<bool> authenticate({
    required String reason,
    required bool biometricOnly,
  });
}

/// Gateway backed by local_auth.
final class SdkBiometricGateway implements BiometricGateway {
  SdkBiometricGateway({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  @override
  Future<bool> canCheckBiometrics() => _localAuth.canCheckBiometrics;

  @override
  Future<bool> isDeviceSupported() => _localAuth.isDeviceSupported();

  @override
  Future<List<BiometricMethod>> availableBiometrics() async {
    final types = await _localAuth.getAvailableBiometrics();
    return types.map(_mapType).toList(growable: false);
  }

  @override
  Future<bool> authenticate({
    required String reason,
    required bool biometricOnly,
  }) {
    return _localAuth.authenticate(
      localizedReason: reason,
      biometricOnly: biometricOnly,
    );
  }

  BiometricMethod _mapType(BiometricType type) {
    return switch (type) {
      BiometricType.face => BiometricMethod.face,
      BiometricType.fingerprint => BiometricMethod.fingerprint,
      BiometricType.iris => BiometricMethod.iris,
      BiometricType.strong => BiometricMethod.strong,
      BiometricType.weak => BiometricMethod.weak,
    };
  }
}
