import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  group('SupportInfo', () {
    test('reports supported state', () {
      const info = SupportInfo.supported(details: <String, Object?>{'a': 1});

      expect(info.isSupported, isTrue);
      expect(info.state, SupportState.supported);
      expect(info.details['a'], 1);
    });

    test('converts platform and device states to typed failures', () {
      const platform = SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'No web implementation.',
      );
      const device = SupportInfo.unsupported(
        SupportState.unsupportedDevice,
        message: 'No fingerprint sensor.',
      );

      expect(platform.toFailure().code, FailureCode.unsupportedPlatform);
      expect(platform.toFailure().kind, FailureKind.unsupported);
      expect(
        platform.toFailure().details['support_state'],
        SupportState.unsupportedPlatform.name,
      );
      expect(device.toFailure().code, FailureCode.unsupportedDevice);
      expect(device.toFailure().kind, FailureKind.unsupported);
    });

    test('converts permission and configuration states', () {
      const permission = SupportInfo.unsupported(
        SupportState.permissionDenied,
        message: 'Not enrolled.',
      );
      const configuration = SupportInfo.unsupported(
        SupportState.notConfigured,
        message: 'Missing key.',
      );

      expect(permission.toFailure().code, FailureCode.permissionDenied);
      expect(permission.toFailure().kind, FailureKind.permission);
      expect(configuration.toFailure().code, FailureCode.configurationMissing);
      expect(configuration.toFailure().kind, FailureKind.configuration);
    });

    test('SupportRegistry records and streams updates', () async {
      final registry = SupportRegistry();
      final updates = <Map<String, SupportInfo>>[];
      final subscription = registry.changes.listen(updates.add);

      registry.record('biometric', const SupportInfo.supported());
      registry.record(
        'camera',
        const SupportInfo.unsupported(
          SupportState.unsupportedDevice,
          message: 'No camera.',
        ),
      );

      expect(registry['biometric']?.isSupported, isTrue);
      expect(registry['camera']?.isDeviceUnsupported, isTrue);
      expect(registry.all.length, 2);
      expect(updates.length, 2);

      await subscription.cancel();
      await registry.dispose();
    });
  });
}
