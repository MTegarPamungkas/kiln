import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/permission/gate_permission.dart';
import 'package:{{app_name}}/extensions/permission/permission_config.dart';
import 'package:{{app_name}}/extensions/permission/permission_group.dart';

import 'test_support.dart';

Gate _gate(FakePermissionGateway gateway) {
  final registry = GetItRegistry();
  final permissions = createDevicePermissions(gateway: gateway);
  registry
    ..registerSingleton<Permissions>(permissions)
    ..registerSingleton<PermissionGroup>(PermissionGroup(permissions.flow));
  return Gate(registry);
}

void main() {
  test('ensurePermissions requests a group and merges statuses', () async {
    final gateway = FakePermissionGateway(
      statuses: const <PermissionKind, PermissionStatus>{
        PermissionKind.camera: PermissionStatus.granted,
      },
    );
    final gate = _gate(gateway);

    final result = await gate.ensurePermissions(
      const <PermissionKind>[PermissionKind.camera],
      requestIfDenied: false,
    );

    expect(
      result.valueOrNull?[PermissionKind.camera],
      PermissionStatus.granted,
    );
  });

  test('openPermissionSettings delegates to the gateway', () async {
    final gateway = FakePermissionGateway();
    final gate = _gate(gateway);

    final result = await gate.openPermissionSettings();

    expect(result.valueOrNull, isTrue);
    expect(gateway.openSettingsCalls, 1);
  });

  test('a disabled kind is reported as Err, not thrown', () async {
    const config = PermissionConfig(
      activeKinds: <PermissionKind>{PermissionKind.camera},
    );
    final registry = GetItRegistry();
    final permissions = createDevicePermissions(
      config: config,
      gateway: FakePermissionGateway(),
    );
    registry.registerSingleton<Permissions>(permissions);
    final gate = Gate(registry);

    final result = await gate.requestPermission(PermissionKind.microphone);

    expect(
      result.failureOrNull?.code,
      FailureCode.configurationInvalid,
    );
  });
}
