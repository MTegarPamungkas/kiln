import 'package:flutter/foundation.dart';

/// Biometric capabilities of the device.
enum BiometricAvailability {
  available,
  notEnrolled,
  noHardware,
  unsupportedPlatform,
}

/// A biometric method reported by the platform.
enum BiometricMethod { face, fingerprint, iris, strong, weak }

/// Resolves availability from platform signals.
BiometricAvailability resolveBiometricAvailability({
  required TargetPlatform platform,
  bool isWeb = false,
  required bool supported,
  required bool canCheck,
  required bool hasMethods,
}) {
  if (isWeb ||
      (platform != TargetPlatform.android &&
          platform != TargetPlatform.iOS &&
          platform != TargetPlatform.macOS)) {
    return BiometricAvailability.unsupportedPlatform;
  }
  if (!supported) {
    return BiometricAvailability.noHardware;
  }
  if (hasMethods) {
    return BiometricAvailability.available;
  }
  return canCheck
      ? BiometricAvailability.notEnrolled
      : BiometricAvailability.noHardware;
}
