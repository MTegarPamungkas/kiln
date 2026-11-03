import 'package:kiln_core/kiln_core.dart';

import 'permission_flow.dart';
import 'permission_gateway.dart';
import 'permission_kind_guard.dart';
import 'permission_status_cache.dart';

/// [Permissions] implementation backed by a PermissionGateway.
final class DevicePermissions implements Permissions {
  DevicePermissions({
    required this.gateway,
    required this.flow,
    required this.cache,
    required this.guard,
  });

  final PermissionGateway gateway;
  final PermissionFlow flow;
  final PermissionStatusCache cache;
  final PermissionKindGuard guard;

  @override
  Future<PermissionStatus> status(PermissionKind kind) async {
    guard.ensure(kind);
    final cached = cache.get(kind);
    if (cached != null) {
      return cached;
    }
    final status = await gateway.status(kind);
    cache.set(kind, status);
    return status;
  }

  @override
  Future<PermissionStatus> request(PermissionKind kind) async {
    guard.ensure(kind);
    final status = await gateway.request(kind);
    cache.set(kind, status);
    return status;
  }

  @override
  Future<PermissionStatus> ensure(
    PermissionKind kind, {
    bool requestIfDenied = true,
  }) {
    return flow.ensure(kind, requestIfDenied: requestIfDenied);
  }

  @override
  Future<bool> openSettings() => gateway.openSettings();
}
