import 'package:kiln_core/kiln_core.dart';

import 'permission_flow.dart';

/// Requests a group of permissions and merges the results.
final class PermissionGroup {
  const PermissionGroup(this.flow);

  final PermissionFlow flow;

  Future<Map<PermissionKind, PermissionStatus>> ensureAll(
    Iterable<PermissionKind> kinds, {
    bool requestIfDenied = true,
  }) async {
    final results = <PermissionKind, PermissionStatus>{};
    for (final kind in kinds) {
      results[kind] = await flow.ensure(
        kind,
        requestIfDenied: requestIfDenied,
      );
    }
    return results;
  }
}
