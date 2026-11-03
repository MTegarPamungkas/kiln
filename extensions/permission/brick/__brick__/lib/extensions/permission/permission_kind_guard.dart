import 'package:kiln_core/kiln_core.dart';

import 'permission_config.dart';

/// Rejects permission kinds that were not enabled at install time.
final class PermissionKindGuard {
  const PermissionKindGuard(this.config);

  final PermissionConfig config;

  void ensure(PermissionKind kind) {
    if (!config.activeKinds.contains(kind)) {
      throw Failure(
        code: FailureCode.configurationInvalid,
        message: 'Permission "$kind" is not enabled for this app',
        kind: FailureKind.configuration,
      );
    }
  }
}
