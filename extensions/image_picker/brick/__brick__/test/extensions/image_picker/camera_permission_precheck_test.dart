import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/image_picker/camera_permission_precheck.dart';

final class _UnavailablePermissions implements Permissions {
  const _UnavailablePermissions();

  @override
  Future<PermissionStatus> status(PermissionKind kind) async {
    throw const Failure(
      code: FailureCode.configurationInvalid,
      message: 'Permission extension is not installed',
      kind: FailureKind.configuration,
    );
  }

  @override
  Future<PermissionStatus> request(PermissionKind kind) => status(kind);

  @override
  Future<PermissionStatus> ensure(
    PermissionKind kind, {
    bool requestIfDenied = true,
  }) => status(kind);

  @override
  Future<bool> openSettings() async => false;
}

void main() {
  test('checks the camera contract before opening the camera', () async {
    final permissions = FakePermissions();
    final precheck = CameraPermissionPrecheck(permissions: permissions);

    await precheck.ensure(MediaSource.camera);

    expect(permissions.statusChecks, [PermissionKind.camera]);
  });

  test('skips the check for the gallery', () async {
    final permissions = FakePermissions();
    final precheck = CameraPermissionPrecheck(permissions: permissions);

    await precheck.ensure(MediaSource.gallery);

    expect(permissions.statusChecks, isEmpty);
  });

  test('throws when the camera permission is denied', () async {
    final permissions = FakePermissions()
      ..requestResult = PermissionStatus.denied;
    final precheck = CameraPermissionPrecheck(permissions: permissions);

    await expectLater(
      precheck.ensure(MediaSource.camera),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.mediaPermissionDenied,
        ),
      ),
    );
  });

  test('does nothing without a permission contract', () async {
    await const CameraPermissionPrecheck().ensure(MediaSource.camera);
  });

  test('ignores a contract that cannot answer', () async {
    await const CameraPermissionPrecheck(
      permissions: _UnavailablePermissions(),
    ).ensure(MediaSource.camera);
  });
}
