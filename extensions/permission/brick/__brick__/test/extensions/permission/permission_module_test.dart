import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/permission/permission_config.dart';
import 'package:{{app_name}}/extensions/permission/permission_flow.dart';
import 'package:{{app_name}}/extensions/permission/permission_group.dart';
import 'package:{{app_name}}/extensions/permission/permission_module.dart';

void main() {
  test('module registers Permissions and attaches the resume observer', () {
    final registry = GetItRegistry()
      ..registerSingleton<LifecycleController>(LifecycleController());

    const PermissionModule().register(registry);

    expect(registry.read<Permissions>(), isA<Permissions>());
    expect(registry.read<PermissionConfig>(), isA<PermissionConfig>());
    expect(registry.read<PermissionFlow>(), isA<PermissionFlow>());
    expect(registry.read<PermissionGroup>(), isA<PermissionGroup>());
    expect(
      registry.read<LifecycleController>().listeners,
      isNotEmpty,
    );
  });
}
