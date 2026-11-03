import 'package:kiln_core/kiln_core.dart';

import 'permission_gateway.dart';
import 'permission_kind_guard.dart';
import 'permission_status_cache.dart';
import 'permission_support.dart';

typedef RationaleHandler = Future<bool> Function(PermissionKind kind);

/// Runs status, rationale, request, and settings fallback for one permission.
final class PermissionFlow {
  const PermissionFlow({
    required this.gateway,
    required this.guard,
    required this.cache,
    required this.support,
    this.rationale,
  });

  final PermissionGateway gateway;
  final PermissionKindGuard guard;
  final PermissionStatusCache cache;
  final PermissionSupport support;
  final RationaleHandler? rationale;

  Future<PermissionStatus> ensure(
    PermissionKind kind, {
    bool requestIfDenied = true,
  }) async {
    guard.ensure(kind);
    final info = await support.forKind(kind);
    if (!info.isSupported) {
      return PermissionStatus.unsupported;
    }
    final cached = cache.get(kind);
    if (cached != null && cached.isGranted) {
      return cached;
    }

    var status = await gateway.status(kind);
    cache.set(kind, status);
    if (status.isGranted) {
      return status;
    }
    if (status == PermissionStatus.permanentlyDenied) {
      await gateway.openSettings();
      return status;
    }
    if (!requestIfDenied) {
      return status;
    }

    final handler = rationale;
    if (handler != null) {
      final allowed = await handler(kind);
      if (!allowed) {
        return status;
      }
    }

    status = await gateway.request(kind);
    cache.set(kind, status);
    if (status == PermissionStatus.permanentlyDenied) {
      await gateway.openSettings();
    }
    return status;
  }
}
