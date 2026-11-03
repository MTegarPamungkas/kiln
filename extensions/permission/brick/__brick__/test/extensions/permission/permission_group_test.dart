import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/permission/permission_config.dart';
import 'package:{{app_name}}/extensions/permission/permission_flow.dart';
import 'package:{{app_name}}/extensions/permission/permission_group.dart';
import 'package:{{app_name}}/extensions/permission/permission_kind_guard.dart';
import 'package:{{app_name}}/extensions/permission/permission_status_cache.dart';
import 'package:{{app_name}}/extensions/permission/permission_support.dart';

import 'test_support.dart';

void main() {
  test('requests every kind and merges results', () async {
    final gateway = FakePermissionGateway(
      statuses: {
        PermissionKind.camera: PermissionStatus.granted,
        PermissionKind.microphone: PermissionStatus.denied,
      },
    );
    final cache = PermissionStatusCache();
    const config = PermissionConfig(
      activeKinds: {PermissionKind.camera, PermissionKind.microphone},
    );
    final flow = PermissionFlow(
      gateway: gateway,
      guard: const PermissionKindGuard(config),
      cache: cache,
      support: PermissionSupport(config: config, gateway: gateway),
    );
    final group = PermissionGroup(flow);

    final results = await group.ensureAll(const [
      PermissionKind.camera,
      PermissionKind.microphone,
    ], requestIfDenied: false);

    expect(results[PermissionKind.camera], PermissionStatus.granted);
    expect(results[PermissionKind.microphone], PermissionStatus.denied);
  });
}
