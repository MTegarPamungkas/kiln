import 'package:kiln_core/kiln_core.dart';

import 'permission_failure_mapper.dart';
import 'permission_flow.dart';
import 'permission_gateway.dart';
import 'permission_kind_guard.dart';
import 'permission_status_cache.dart';
import 'permission_support.dart';

/// [Permissions] implementation backed by a PermissionGateway.
final class DevicePermissions implements Permissions {
  DevicePermissions({
    required this.gateway,
    required this.flow,
    required this.cache,
    required this.guard,
    required this.support,
  });

  final PermissionGateway gateway;
  final PermissionFlow flow;
  final PermissionStatusCache cache;
  final PermissionKindGuard guard;
  final PermissionSupport support;

  @override
  Future<PermissionStatus> status(PermissionKind kind) => _guard(() async {
    guard.ensure(kind);
    final info = await support.forKind(kind);
    if (!info.isSupported) {
      return PermissionStatus.unsupported;
    }
    final cached = cache.get(kind);
    if (cached != null) {
      return cached;
    }
    final status = await gateway.status(kind);
    cache.set(kind, status);
    return status;
  });

  @override
  Future<PermissionStatus> request(PermissionKind kind) => _guard(() async {
    guard.ensure(kind);
    final info = await support.forKind(kind);
    if (!info.isSupported) {
      return PermissionStatus.unsupported;
    }
    final status = await gateway.request(kind);
    cache.set(kind, status);
    return status;
  });

  @override
  Future<PermissionStatus> ensure(
    PermissionKind kind, {
    bool requestIfDenied = true,
  }) => _guard(
    () => flow.ensure(kind, requestIfDenied: requestIfDenied),
  );

  @override
  Future<bool> openSettings() => _guard(gateway.openSettings);

  /// Runs [action], mapping unexpected platform errors to a permission
  /// [Failure]. Existing [Failure]s, such as the kind guard, pass through.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      throw mapPermissionError(error, stackTrace: stackTrace);
    }
  }
}
