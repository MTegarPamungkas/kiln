import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/permission/permission_config.dart';
import 'package:{{app_name}}/extensions/permission/permission_support.dart';

import 'test_support.dart';

void main() {
  const config = PermissionConfig(
    activeKinds: <PermissionKind>{
      PermissionKind.camera,
      PermissionKind.contacts,
    },
  );

  test('reports configured, supported, and unsupported kinds', () async {
    final gateway = FakePermissionGateway(
      statuses: <PermissionKind, PermissionStatus>{
        PermissionKind.camera: PermissionStatus.granted,
        PermissionKind.contacts: PermissionStatus.restricted,
      },
    );
    final support = PermissionSupport(config: config, gateway: gateway);

    final camera = await support.forKind(PermissionKind.camera);
    final contacts = await support.forKind(PermissionKind.contacts);
    final bluetooth = await support.forKind(PermissionKind.bluetooth);

    expect(camera.isSupported, isTrue);
    expect(contacts.state, SupportState.unsupportedDevice);
    expect(bluetooth.state, SupportState.notConfigured);
  });

  test('maps missing plugin implementations to unsupported platform', () async {
    final gateway = FakePermissionGateway()..statusError = UnsupportedError('');
    final support = PermissionSupport(config: config, gateway: gateway);

    final info = await support.forKind(PermissionKind.camera);

    expect(info.state, SupportState.unsupportedPlatform);
    expect(info.toFailure().code, FailureCode.unsupportedPlatform);
  });

  test('probeAll covers every active kind', () async {
    final gateway = FakePermissionGateway(
      statuses: <PermissionKind, PermissionStatus>{
        PermissionKind.camera: PermissionStatus.granted,
      },
    );
    final support = PermissionSupport(config: config, gateway: gateway);

    final infos = await support.probeAll();

    expect(infos.keys, containsAll(config.activeKinds));
    expect(infos[PermissionKind.camera]?.isSupported, isTrue);
  });

  test('device permissions return unsupported instead of throwing', () async {
    final gateway = FakePermissionGateway()..statusError = UnsupportedError('');
    final permissions = createDevicePermissions(gateway: gateway);

    expect(
      await permissions.status(PermissionKind.camera),
      PermissionStatus.unsupported,
    );
    expect(
      await permissions.ensure(PermissionKind.camera),
      PermissionStatus.unsupported,
    );
  });
}
