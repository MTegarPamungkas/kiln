import 'dart:async';

import 'package:kiln_testing/kiln_testing.dart';

import 'test_support.dart';

void main() {
  deepLinksContract(
    description: 'DeviceDeepLinks',
    create: () {
      final gateway = FakeAppLinksGateway();
      final links = createDeviceDeepLinks(gateway: gateway);
      unawaited(links.start());
      return (deepLinks: links, emit: gateway.emit);
    },
  );
}
