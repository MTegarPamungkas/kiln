import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';

import 'test_support.dart';

void main() {
  test('NetworkMonitor reports status and changes', () async {
    final gateway = FakeConnectivityGateway(current: NetworkStatus.online);
    final monitor = createTestMonitor(gateway);
    final statuses = <NetworkStatus>[];
    final subscription = monitor.changes.listen(statuses.add);

    await monitor.start();
    gateway.emit(NetworkStatus.offline);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(monitor.status, NetworkStatus.offline);
    expect(statuses, contains(NetworkStatus.offline));

    await subscription.cancel();
    await monitor.dispose();
    await gateway.dispose();
  });
}
