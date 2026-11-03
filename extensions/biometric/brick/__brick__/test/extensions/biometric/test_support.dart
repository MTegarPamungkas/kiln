import 'package:flutter/foundation.dart';
import 'package:{{app_name}}/extensions/biometric/biometric.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_availability.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_config.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_gateway.dart';

final class FakeBiometricGateway implements BiometricGateway {
  bool supported = true;
  bool canCheck = true;
  List<BiometricMethod> methods = <BiometricMethod>[
    BiometricMethod.fingerprint,
  ];
  bool result = true;
  Object? failure;
  int authCalls = 0;
  String? lastReason;
  bool? lastBiometricOnly;

  @override
  Future<bool> canCheckBiometrics() async => canCheck;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<List<BiometricMethod>> availableBiometrics() async => methods;

  @override
  Future<bool> authenticate({
    required String reason,
    required bool biometricOnly,
  }) async {
    authCalls++;
    lastReason = reason;
    lastBiometricOnly = biometricOnly;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return result;
  }
}

Biometric createBiometric({
  FakeBiometricGateway? gateway,
  BiometricConfig config = const BiometricConfig(),
  TargetPlatform platform = TargetPlatform.android,
  bool isWeb = false,
}) {
  return Biometric(
    gateway: gateway ?? FakeBiometricGateway(),
    config: config,
    platform: platform,
    isWeb: isWeb,
  );
}
