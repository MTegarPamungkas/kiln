import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

/// Biometric capabilities of the device.
enum BiometricAvailability {
  available,
  notEnrolled,
  noHardware,
  unsupportedPlatform,
}

extension BiometricAvailabilitySupport on BiometricAvailability {
  /// Converts the probe into the shared support contract.
  SupportInfo get supportInfo => switch (this) {
    BiometricAvailability.available => const SupportInfo.supported(),
    BiometricAvailability.notEnrolled => const SupportInfo.unsupported(
      SupportState.permissionDenied,
      message: 'Biometrics are not enrolled on this device.',
    ),
    BiometricAvailability.noHardware => const SupportInfo.unsupported(
      SupportState.unsupportedDevice,
      message: 'This device has no biometric hardware.',
    ),
    BiometricAvailability.unsupportedPlatform => const SupportInfo.unsupported(
      SupportState.unsupportedPlatform,
      message: 'Biometrics are not supported on this platform.',
    ),
  };
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
