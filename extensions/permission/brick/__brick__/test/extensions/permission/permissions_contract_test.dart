import 'package:kiln_testing/kiln_testing.dart';

import 'test_support.dart';

void main() {
  permissionsContract(
    create: () {
      final gateway = FakePermissionGateway();
      final permissions = createDevicePermissions(gateway: gateway);
      return (permissions: permissions, setStatus: gateway.setStatus);
    },
    description: 'DevicePermissions',
  );
}
