import 'package:kiln_core/kiln_core.dart';

import 'permission_group.dart';

/// Gate verbs for the permission capability beyond the single-kind helpers.
///
/// `gate.permissionStatus` and `gate.requestPermission` already cover one
/// permission at a time. This adds batch requests through [PermissionGroup] and
/// a verb to open the platform settings screen. The SDK returns results; the
/// app renders rationale and settings prompts itself.
extension GatePermissionX on Gate {
  PermissionGroup get permissionGroup => use<PermissionGroup>();

  /// Requests several permissions and returns each final status in one call.
  Future<Result<Map<PermissionKind, PermissionStatus>>> ensurePermissions(
    Iterable<PermissionKind> kinds, {
    bool requestIfDenied = true,
  }) => call(
    () => permissionGroup.ensureAll(kinds, requestIfDenied: requestIfDenied),
  );

  /// Opens the platform settings screen; `Ok(false)` when it cannot open.
  Future<Result<bool>> openPermissionSettings() =>
      call(permissions.openSettings);
}
