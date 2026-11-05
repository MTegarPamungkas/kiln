import 'package:kiln_core/kiln_core.dart';

/// [Permissions] with per-kind statuses controlled by the test.
final class FakePermissions implements Permissions {
  FakePermissions({
    Map<PermissionKind, PermissionStatus> statuses =
        const <PermissionKind, PermissionStatus>{},
  }) : _statuses = <PermissionKind, PermissionStatus>{...statuses};

  final Map<PermissionKind, PermissionStatus> _statuses;
  final List<PermissionKind> statusChecks = <PermissionKind>[];
  final List<PermissionKind> requests = <PermissionKind>[];
  PermissionStatus requestResult = PermissionStatus.granted;
  bool openSettingsResult = true;
  int openSettingsCalls = 0;

  void setStatus(PermissionKind kind, PermissionStatus status) {
    _statuses[kind] = status;
  }

  @override
  Future<PermissionStatus> status(PermissionKind kind) async {
    statusChecks.add(kind);
    return _statuses[kind] ?? PermissionStatus.denied;
  }

  @override
  Future<PermissionStatus> request(PermissionKind kind) async {
    requests.add(kind);
    _statuses[kind] = requestResult;
    return requestResult;
  }

  @override
  Future<PermissionStatus> ensure(
    PermissionKind kind, {
    bool requestIfDenied = true,
  }) async {
    final current = await status(kind);
    if (current.isGranted || !requestIfDenied) {
      return current;
    }
    return request(kind);
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return openSettingsResult;
  }
}
