import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_availability.dart';

void main() {
  test('is available when methods are enrolled', () {
    expect(
      resolveBiometricAvailability(
        platform: TargetPlatform.android,
        supported: true,
        canCheck: true,
        hasMethods: true,
      ),
      BiometricAvailability.available,
    );
  });

  test('reports not enrolled', () {
    expect(
      resolveBiometricAvailability(
        platform: TargetPlatform.iOS,
        supported: true,
        canCheck: true,
        hasMethods: false,
      ),
      BiometricAvailability.notEnrolled,
    );
  });

  test('reports missing hardware', () {
    expect(
      resolveBiometricAvailability(
        platform: TargetPlatform.android,
        supported: true,
        canCheck: false,
        hasMethods: false,
      ),
      BiometricAvailability.noHardware,
    );
  });

  test('reports unsupported platforms', () {
    expect(
      resolveBiometricAvailability(
        platform: TargetPlatform.linux,
        supported: true,
        canCheck: true,
        hasMethods: true,
      ),
      BiometricAvailability.unsupportedPlatform,
    );
    expect(
      resolveBiometricAvailability(
        platform: TargetPlatform.linux,
        isWeb: true,
        supported: true,
        canCheck: true,
        hasMethods: true,
      ),
      BiometricAvailability.unsupportedPlatform,
    );
  });

  test('maps availability to the shared support contract', () {
    expect(BiometricAvailability.available.supportInfo.isSupported, isTrue);
    expect(
      BiometricAvailability.noHardware.supportInfo.state,
      SupportState.unsupportedDevice,
    );
    expect(
      BiometricAvailability.notEnrolled.supportInfo.state,
      SupportState.permissionDenied,
    );
    expect(
      BiometricAvailability.unsupportedPlatform.supportInfo.state,
      SupportState.unsupportedPlatform,
    );
  });
}
