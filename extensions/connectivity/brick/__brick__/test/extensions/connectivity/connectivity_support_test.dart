import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_support.dart';

import 'test_support.dart';

void main() {
  test('reports supported even while offline', () async {
    final gateway = FakeConnectivityGateway(current: NetworkStatus.offline);
    final support = ConnectivitySupport(gateway: gateway);

    final info = await support.check();

    expect(info.isSupported, isTrue);
    expect(info.details['status'], 'offline');
    await gateway.dispose();
  });

  test('caches the probe until cleared', () async {
    final gateway = FakeConnectivityGateway(current: NetworkStatus.online);
    final support = ConnectivitySupport(gateway: gateway);

    await support.check();
    gateway.checkError = StateError('now broken');
    expect((await support.check()).isSupported, isTrue);

    support.clear();
    expect((await support.check()).isSupported, isFalse);
    await gateway.dispose();
  });

  test('maps a missing plugin to unsupported platform', () async {
    final gateway = FakeConnectivityGateway()
      ..checkError = MissingPluginException('no connectivity');
    final support = ConnectivitySupport(gateway: gateway);

    final info = await support.check();

    expect(info.state, SupportState.unsupportedPlatform);
    expect(info.toFailure().code, FailureCode.unsupportedPlatform);
    await gateway.dispose();
  });

  test('maps other failures to unavailable', () async {
    final gateway = FakeConnectivityGateway()
      ..checkError = StateError('platform failed');
    final support = ConnectivitySupport(gateway: gateway);

    final info = await support.check();

    expect(info.state, SupportState.unavailable);
    await gateway.dispose();
  });

  test('monitor can retry after a failed start', () async {
    final gateway = FakeConnectivityGateway(current: NetworkStatus.online)
      ..checkError = StateError('temporary failure');
    final monitor = createTestMonitor(gateway);

    await expectLater(monitor.start(), throwsStateError);
    gateway.checkError = null;
    await monitor.start();

    expect(monitor.status, NetworkStatus.online);
    await monitor.dispose();
    await gateway.dispose();
  });
}
