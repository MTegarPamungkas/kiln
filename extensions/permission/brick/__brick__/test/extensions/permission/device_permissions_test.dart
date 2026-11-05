import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/permission/permission_config.dart';

import 'test_support.dart';

void main() {
  test('status and request use the gateway and cache', () async {
    final gateway = FakePermissionGateway(
      statuses: {PermissionKind.camera: PermissionStatus.denied},
    );
    final permissions = createDevicePermissions(gateway: gateway);

    expect(
      await permissions.status(PermissionKind.camera),
      PermissionStatus.denied,
    );
    gateway.setStatus(PermissionKind.camera, PermissionStatus.granted);
    expect(
      await permissions.status(PermissionKind.camera),
      PermissionStatus.denied,
    );

    gateway.requestResult = PermissionStatus.granted;
    expect(
      await permissions.request(PermissionKind.camera),
      PermissionStatus.granted,
    );
    expect(
      await permissions.status(PermissionKind.camera),
      PermissionStatus.granted,
    );
  });

  test('openSettings delegates to the gateway', () async {
    final gateway = FakePermissionGateway();
    final permissions = createDevicePermissions(gateway: gateway);

    expect(await permissions.openSettings(), isTrue);
    expect(gateway.openSettingsCalls, 1);
  });

  test('inactive kinds are rejected', () async {
    final permissions = createDevicePermissions(
      config: const PermissionConfig(activeKinds: {PermissionKind.camera}),
    );

    await expectLater(
      permissions.status(PermissionKind.microphone),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.configurationInvalid,
        ),
      ),
    );
  });
}
