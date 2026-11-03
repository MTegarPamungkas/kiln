import 'package:kiln_core/kiln_core.dart';

/// Caches permission statuses until the app resumes.
final class PermissionStatusCache {
  final Map<PermissionKind, PermissionStatus> _statuses =
      <PermissionKind, PermissionStatus>{};

  PermissionStatus? get(PermissionKind kind) => _statuses[kind];

  void set(PermissionKind kind, PermissionStatus status) {
    _statuses[kind] = status;
  }

  void clear() {
    _statuses.clear();
  }
}
