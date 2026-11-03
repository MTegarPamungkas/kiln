import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

import 'biometric_availability.dart';
import 'biometric_config.dart';
import 'biometric_failure_mapper.dart';
import 'biometric_gateway.dart';

/// High-level biometric facade.
final class Biometric {
  Biometric({
    required this.gateway,
    this.config = BiometricConfig.defaults,
    TargetPlatform? platform,
    this.isWeb = false,
  }) : platform = platform ?? defaultTargetPlatform;

  final BiometricGateway gateway;
  final BiometricConfig config;
  final TargetPlatform platform;
  final bool isWeb;

  Future<BiometricAvailability> availability() async {
    final supported = await gateway.isDeviceSupported();
    final canCheck = supported && await gateway.canCheckBiometrics();
    final methods = canCheck
        ? await gateway.availableBiometrics()
        : const <BiometricMethod>[];
    return resolveBiometricAvailability(
      platform: platform,
      isWeb: isWeb,
      supported: supported,
      canCheck: canCheck,
      hasMethods: methods.isNotEmpty,
    );
  }

  Future<List<BiometricMethod>> availableBiometrics() {
    return gateway.availableBiometrics();
  }

  /// Prompts for biometrics; false means the user failed the challenge.
  Future<bool> authenticate({String? reason}) async {
    try {
      final availability = await this.availability();
      if (availability == BiometricAvailability.unsupportedPlatform ||
          availability == BiometricAvailability.noHardware) {
        throw const Failure(
          code: FailureCode.unavailable,
          message: 'Biometrik tidak tersedia di perangkat ini.',
          kind: FailureKind.unavailable,
        );
      }
      if (availability == BiometricAvailability.notEnrolled) {
        throw const Failure(
          code: FailureCode.permissionDenied,
          message: 'Biometrik belum terdaftar di perangkat.',
          kind: FailureKind.permission,
        );
      }
      return await gateway.authenticate(
        reason: reason ?? config.reason,
        biometricOnly: config.biometricOnly,
      );
    } on Object catch (error, stackTrace) {
      throw mapBiometricError(error, stackTrace: stackTrace);
    }
  }
}
