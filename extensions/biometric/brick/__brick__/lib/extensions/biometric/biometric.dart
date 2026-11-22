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
    // `canCheckBiometrics` maps to the platform's hardware probe
    // (Android `deviceCanSupportBiometrics`), which stays true when the
    // hardware exists but nothing is enrolled. `isDeviceSupported` is broader:
    // it is also true for a device with only a screen-lock credential, and
    // false for a user profile with neither, so it cannot tell "no hardware"
    // from "hardware, nothing enrolled".
    final hasHardware = await gateway.canCheckBiometrics();
    final supported = hasHardware || await gateway.isDeviceSupported();
    final methods = hasHardware
        ? await gateway.availableBiometrics()
        : const <BiometricMethod>[];
    return resolveBiometricAvailability(
      platform: platform,
      isWeb: isWeb,
      supported: supported,
      canCheck: hasHardware,
      hasMethods: methods.isNotEmpty,
    );
  }

  Future<SupportInfo> support() async => (await availability()).supportInfo;

  Future<List<BiometricMethod>> availableBiometrics() {
    return gateway.availableBiometrics();
  }

  /// Prompts for biometrics; false means the user failed the challenge.
  Future<bool> authenticate({String? reason}) async {
    try {
      final availability = await this.availability();
      final support = availability.supportInfo;
      if (!support.isSupported) {
        throw support.toFailure();
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
