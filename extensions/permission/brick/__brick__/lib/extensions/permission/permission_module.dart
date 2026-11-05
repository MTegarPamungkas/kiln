import 'package:kiln_core/kiln_core.dart';

import 'device_permissions.dart';
import 'permission_config.dart';
import 'permission_flow.dart';
import 'permission_gateway.dart';
import 'permission_group.dart';
import 'permission_kind_guard.dart';
import 'permission_resume_observer.dart';
import 'permission_status_cache.dart';
import 'permission_support.dart';

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
    final support = PermissionSupport(config: config, gateway: gateway);
    final flow = PermissionFlow(
      gateway: gateway,
      guard: guard,
      cache: cache,
      support: support,
    );
    final permissions = DevicePermissions(
      gateway: gateway,
      flow: flow,
      cache: cache,
      guard: guard,
      support: support,
    );

    registry
      ..registerSingleton<PermissionConfig>(config)
      ..registerSingleton<PermissionSupport>(support)
      ..registerSingleton<PermissionFlow>(flow)
      ..registerSingleton<PermissionGroup>(PermissionGroup(flow))
      ..registerSingleton<Permissions>(permissions);

    registry.readOrNull<LifecycleController>()?.attach(
      PermissionResumeObserver(cache: cache),
    );
  }

  @override
  Future<SupportInfo> support(Registry registry) async {
    final support = registry.read<PermissionSupport>();
    final infos = await support.probeAll();
    final supported = <String>[
      for (final entry in infos.entries)
        if (entry.value.isSupported) entry.key.name,
    ];
    final unsupported = <String>[
      for (final entry in infos.entries)
        if (!entry.value.isSupported) entry.key.name,
    ];
    if (supported.isEmpty) {
      return SupportInfo.unsupported(
        SupportState.unsupportedDevice,
        message: 'No configured permission is supported on this device.',
        details: <String, Object?>{
          'supported_kinds': supported,
          'unsupported_kinds': unsupported,
        },
      );
    }
    return SupportInfo.supported(
      details: <String, Object?>{
        'supported_kinds': supported,
        'unsupported_kinds': unsupported,
      },
    );
  }
}
