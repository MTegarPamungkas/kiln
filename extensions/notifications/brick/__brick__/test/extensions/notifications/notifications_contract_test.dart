import 'package:kiln_testing/kiln_testing.dart';

import 'test_support.dart';

void main() {
  notificationsContract(
    description: 'DeviceNotifications',
    create: () {
      final gateway = FakeNotificationGateway();
      return (
        notifications: createDeviceNotifications(gateway: gateway),
        emitTap: gateway.emitTap,
      );
    },
  );
}
