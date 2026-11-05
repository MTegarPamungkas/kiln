/// Platform permissions Kiln extensions may request.
enum PermissionKind {
  camera,
  microphone,
  photos,
  notifications,
  location,
  locationAlways,
  contacts,
  calendar,
  bluetooth,
  storage,
}

/// Outcome of a permission check or request.
enum PermissionStatus {
  granted,
  limited,
  denied,
  permanentlyDenied,
  restricted,

  /// The permission does not exist on this platform or device.
  unsupported,
}

extension PermissionStatusX on PermissionStatus {
  bool get isGranted =>
      this == PermissionStatus.granted || this == PermissionStatus.limited;

  bool get isPermanent => this == PermissionStatus.permanentlyDenied;

  bool get isUnsupported => this == PermissionStatus.unsupported;
}

/// Checks and requests platform permissions.
abstract interface class Permissions {
  Future<PermissionStatus> status(PermissionKind kind);

  Future<PermissionStatus> request(PermissionKind kind);

  Future<PermissionStatus> ensure(
    PermissionKind kind, {
    bool requestIfDenied = true,
  });

  Future<bool> openSettings();
}
