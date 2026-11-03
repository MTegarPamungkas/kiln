import 'package:kiln_core/kiln_core.dart';

import 'device_permissions.dart';
import 'permission_config.dart';
import 'permission_flow.dart';
import 'permission_gateway.dart';
import 'permission_kind_guard.dart';
import 'permission_resume_observer.dart';
import 'permission_status_cache.dart';

/// Registers Permissions and the resume observer.
final class PermissionModule extends KilnModule {
  const PermissionModule();

  @override
  String get id => 'permission';

  @override
  Set<String> get provides => const <String>{'permission'};

  @override
  void register(Registry registry) {
    const config = PermissionConfig.defaults;
    const gateway = SdkPermissionGateway();
    final cache = PermissionStatusCache();
    final guard = PermissionKindGuard(config);
    final flow = PermissionFlow(
      gateway: gateway,
      guard: guard,
      cache: cache,
    );
    final permissions = DevicePermissions(
      gateway: gateway,
      flow: flow,
      cache: cache,
      guard: guard,
    );

    registry
      ..registerSingleton<PermissionConfig>(config)
      ..registerSingleton<Permissions>(permissions);

    registry.readOrNull<LifecycleController>()?.attach(
      PermissionResumeObserver(cache: cache),
    );
  }
}
