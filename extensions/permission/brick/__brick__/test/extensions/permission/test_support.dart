import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/permission/device_permissions.dart';
import 'package:{{app_name}}/extensions/permission/permission_config.dart';
import 'package:{{app_name}}/extensions/permission/permission_flow.dart';
import 'package:{{app_name}}/extensions/permission/permission_gateway.dart';
import 'package:{{app_name}}/extensions/permission/permission_kind_guard.dart';
import 'package:{{app_name}}/extensions/permission/permission_status_cache.dart';

final class FakePermissionGateway implements PermissionGateway {
  FakePermissionGateway({Map<PermissionKind, PermissionStatus>? statuses})
    : statuses = <PermissionKind, PermissionStatus>{...?statuses};

  final Map<PermissionKind, PermissionStatus> statuses;
  PermissionStatus requestResult = PermissionStatus.granted;
  bool openSettingsResult = true;
  int openSettingsCalls = 0;

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return openSettingsResult;
  }

  @override
  Future<PermissionStatus> request(PermissionKind kind) async {
    statuses[kind] = requestResult;
    return requestResult;
  }

  @override
  Future<PermissionStatus> status(PermissionKind kind) async {
    return statuses[kind] ?? PermissionStatus.denied;
  }

  void setStatus(PermissionKind kind, PermissionStatus status) {
    statuses[kind] = status;
  }
}

DevicePermissions createDevicePermissions({
  FakePermissionGateway? gateway,
  PermissionConfig config = const PermissionConfig(
    activeKinds: <PermissionKind>{
      PermissionKind.camera,
      PermissionKind.microphone,
      PermissionKind.photos,
      PermissionKind.notifications,
      PermissionKind.location,
      PermissionKind.locationAlways,
      PermissionKind.contacts,
      PermissionKind.calendar,
      PermissionKind.bluetooth,
      PermissionKind.storage,
    },
  ),
  RationaleHandler? rationale,
}) {
  final effectiveGateway = gateway ?? FakePermissionGateway();
  final cache = PermissionStatusCache();
  final guard = PermissionKindGuard(config);
  final flow = PermissionFlow(
    gateway: effectiveGateway,
    guard: guard,
    cache: cache,
    rationale: rationale,
  );
  return DevicePermissions(
    gateway: effectiveGateway,
    flow: flow,
    cache: cache,
    guard: guard,
  );
}
