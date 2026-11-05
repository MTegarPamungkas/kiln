import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/notifications/notification_permission_flow.dart';

import 'test_support.dart';

final class _FailingPermissions implements Permissions {
  const _FailingPermissions();

  @override
  Future<PermissionStatus> status(PermissionKind kind) async {
    throw const Failure(
      code: FailureCode.unavailable,
      message: 'No permission handler on this platform',
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
  test('uses the Permissions contract when it is registered', () async {
    final gateway = FakeNotificationGateway();
    final flow = NotificationPermissionFlow(
      gateway: gateway,
      permissions: FakePermissions(),
    );

    expect(await flow.request(), isTrue);
    expect(gateway.permissionCalls, 0);
  });

  test('falls back to the plugin when the contract is absent', () async {
    final gateway = FakeNotificationGateway()..permissionResult = false;
    final flow = NotificationPermissionFlow(gateway: gateway);

    expect(await flow.request(), isFalse);
    expect(gateway.permissionCalls, 1);
  });

  test('falls back to the plugin when the contract fails', () async {
    final gateway = FakeNotificationGateway();
    final flow = NotificationPermissionFlow(
      gateway: gateway,
      permissions: const _FailingPermissions(),
    );

    expect(await flow.request(), isTrue);
    expect(gateway.permissionCalls, 1);
  });
}
