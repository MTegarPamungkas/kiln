import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';

import 'test_support.dart';

void main() {
  test('returns granted without requesting', () async {
    final gateway = FakePermissionGateway(
      statuses: {PermissionKind.camera: PermissionStatus.granted},
    );
    final permissions = createDevicePermissions(gateway: gateway);

    expect(
      await permissions.ensure(PermissionKind.camera),
      PermissionStatus.granted,
    );
  });

  test('requestIfDenied false returns the current status', () async {
    final gateway = FakePermissionGateway(
      statuses: {PermissionKind.photos: PermissionStatus.denied},
    );
    final permissions = createDevicePermissions(gateway: gateway);

    expect(
      await permissions.ensure(
        PermissionKind.photos,
        requestIfDenied: false,
      ),
      PermissionStatus.denied,
    );
  });

  test('rationale rejection prevents the request', () async {
    final gateway = FakePermissionGateway(
      statuses: {PermissionKind.microphone: PermissionStatus.denied},
    );
    var rationaleCalls = 0;
    final permissions = createDevicePermissions(
      gateway: gateway,
      rationale: (_) async {
        rationaleCalls++;
        return false;
      },
    );

    expect(
      await permissions.ensure(PermissionKind.microphone),
      PermissionStatus.denied,
    );
    expect(rationaleCalls, 1);
  });

  test('permanent denial opens settings', () async {
    final gateway = FakePermissionGateway(
      statuses: {PermissionKind.storage: PermissionStatus.permanentlyDenied},
    );
    final permissions = createDevicePermissions(gateway: gateway);

    expect(
      await permissions.ensure(PermissionKind.storage),
      PermissionStatus.permanentlyDenied,
    );
    expect(gateway.openSettingsCalls, 1);
  });
}
