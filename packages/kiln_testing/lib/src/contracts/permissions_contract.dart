import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef PermissionsContractFactory =
    ({
      Permissions permissions,
      void Function(PermissionKind kind, PermissionStatus status) setStatus,
    })
    Function();

/// Behavior every [Permissions] implementation must share.
void permissionsContract({
  required PermissionsContractFactory create,
  String description = 'Permissions',
}) {
  group('$description contract', () {
    test('status reports the status configured for the kind', () async {
      final harness = create();
      harness.setStatus(PermissionKind.camera, PermissionStatus.granted);

      expect(
        await harness.permissions.status(PermissionKind.camera),
        PermissionStatus.granted,
      );
    });

    test('request returns a permission status', () async {
      final harness = create();

      expect(
        await harness.permissions.request(PermissionKind.microphone),
        isA<PermissionStatus>(),
      );
    });

    test(
      'ensure returns granted without asking when already granted',
      () async {
        final harness = create();
        harness.setStatus(PermissionKind.photos, PermissionStatus.granted);

        expect(
          await harness.permissions.ensure(PermissionKind.photos),
          PermissionStatus.granted,
        );
      },
    );

    test('ensure can skip the request when denied', () async {
      final harness = create();
      harness.setStatus(PermissionKind.storage, PermissionStatus.denied);

      expect(
        await harness.permissions.ensure(
          PermissionKind.storage,
          requestIfDenied: false,
        ),
        PermissionStatus.denied,
      );
    });

    test('openSettings reports a boolean', () async {
      final harness = create();

      expect(await harness.permissions.openSettings(), isA<bool>());
    });
  });
}
