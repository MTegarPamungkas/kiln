import 'package:kiln_core/kiln_core.dart';

/// Checks camera permission before opening the camera, when available.
final class CameraPermissionPrecheck {
  const CameraPermissionPrecheck({this.permissions});

  final Permissions? permissions;

  Future<void> ensure(MediaSource source) async {
    if (source != MediaSource.camera) {
      return;
    }
    final contract = permissions;
    if (contract == null) {
      return;
    }
    try {
      final status = await contract.ensure(PermissionKind.camera);
      if (!status.isGranted) {
        throw const Failure(
          code: FailureCode.mediaPermissionDenied,
          message: 'Izin kamera ditolak.',
          kind: FailureKind.permission,
        );
      }
    } on Failure catch (failure) {
      if (failure.isPermissionFailure ||
          failure.code == FailureCode.mediaPermissionDenied) {
        rethrow;
      }
      // The permission contract cannot answer here; the picker plugin will
      // surface its own error.
    }
  }
}
