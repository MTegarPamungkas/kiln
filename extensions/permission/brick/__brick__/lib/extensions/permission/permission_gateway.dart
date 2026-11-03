import 'package:kiln_core/kiln_core.dart' as core;
import 'package:permission_handler/permission_handler.dart' as ph;

/// Platform permission access that can be faked in tests.
abstract interface class PermissionGateway {
  Future<core.PermissionStatus> status(core.PermissionKind kind);

  Future<core.PermissionStatus> request(core.PermissionKind kind);

  Future<bool> openSettings();
}

/// Gateway backed by permission_handler.
final class SdkPermissionGateway implements PermissionGateway {
  const SdkPermissionGateway();

  ph.Permission _permission(core.PermissionKind kind) {
    return switch (kind) {
      core.PermissionKind.camera => ph.Permission.camera,
      core.PermissionKind.microphone => ph.Permission.microphone,
      core.PermissionKind.photos => ph.Permission.photos,
      core.PermissionKind.notifications => ph.Permission.notification,
      core.PermissionKind.location => ph.Permission.locationWhenInUse,
      core.PermissionKind.locationAlways => ph.Permission.locationAlways,
      core.PermissionKind.contacts => ph.Permission.contacts,
      core.PermissionKind.calendar => ph.Permission.calendarFullAccess,
      core.PermissionKind.bluetooth => ph.Permission.bluetooth,
      core.PermissionKind.storage => ph.Permission.storage,
    };
  }

  core.PermissionStatus _map(ph.PermissionStatus status) {
    return switch (status) {
      ph.PermissionStatus.granted => core.PermissionStatus.granted,
      ph.PermissionStatus.limited => core.PermissionStatus.limited,
      ph.PermissionStatus.denied => core.PermissionStatus.denied,
      ph.PermissionStatus.permanentlyDenied =>
        core.PermissionStatus.permanentlyDenied,
      ph.PermissionStatus.restricted => core.PermissionStatus.restricted,
      ph.PermissionStatus.provisional => core.PermissionStatus.limited,
    };
  }

  @override
  Future<core.PermissionStatus> status(core.PermissionKind kind) async {
    return _map(await _permission(kind).status);
  }

  @override
  Future<core.PermissionStatus> request(core.PermissionKind kind) async {
    return _map(await _permission(kind).request());
  }

  @override
  Future<bool> openSettings() => ph.openAppSettings();
}
