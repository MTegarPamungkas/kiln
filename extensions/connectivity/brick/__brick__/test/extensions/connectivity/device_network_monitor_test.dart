import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_config.dart';
import 'package:{{app_name}}/extensions/connectivity/device_network_monitor.dart';
import 'package:{{app_name}}/extensions/connectivity/reconnect_trigger.dart';

import 'test_support.dart';

void main() {
  test('starts unknown, checks the gateway, and emits changes', () async {
    final gateway = FakeConnectivityGateway(current: NetworkStatus.online);
    final monitor = createTestMonitor(gateway);
    final statuses = <NetworkStatus>[];
    final subscription = monitor.changes.listen(statuses.add);

    expect(monitor.status, NetworkStatus.unknown);
    await monitor.start();
    expect(monitor.status, NetworkStatus.online);

    gateway.emit(NetworkStatus.offline);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(monitor.status, NetworkStatus.offline);
    expect(statuses, contains(NetworkStatus.offline));

    await subscription.cancel();
    await monitor.dispose();
    await gateway.dispose();
  });

  test('does not emit duplicate statuses', () async {
    final gateway = FakeConnectivityGateway(current: NetworkStatus.online);
    final monitor = createTestMonitor(gateway);
    final statuses = <NetworkStatus>[];
    final subscription = monitor.changes.listen(statuses.add);
    await monitor.start();
    statuses.clear();

    gateway.emit(NetworkStatus.online);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(statuses, isEmpty);
    await subscription.cancel();
    await monitor.dispose();
    await gateway.dispose();
  });

  test('reconnect trigger fires on offline to online', () async {
    var reconnects = 0;
    final gateway = FakeConnectivityGateway(current: NetworkStatus.online);
    final monitor = DeviceNetworkMonitor(
      gateway: gateway,
      config: const ConnectivityConfig(debounceWindow: Duration.zero),
      reconnectTrigger: ReconnectTrigger(onReconnect: () => reconnects++),
    );
    await monitor.start();

    gateway.emit(NetworkStatus.offline);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    gateway.emit(NetworkStatus.online);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(reconnects, 1);
    await monitor.dispose();
    await gateway.dispose();
  });
}
