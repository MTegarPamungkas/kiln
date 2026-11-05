import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef ConnectivityContractFactory =
    ({NetworkMonitor monitor, void Function(NetworkStatus status) emit})
    Function();

/// Behavior every [NetworkMonitor] implementation must share.
void connectivityContract({
  required ConnectivityContractFactory create,
  String description = 'NetworkMonitor',
}) {
  group('$description contract', () {
    test('reports a valid current status', () {
      final harness = create();

      expect(harness.monitor.status, isA<NetworkStatus>());
    });

    test('emits status changes and updates the current status', () async {
      final harness = create();
      final statuses = <NetworkStatus>[];
      final subscription = harness.monitor.changes.listen(statuses.add);

      harness.emit(NetworkStatus.online);
      harness.emit(NetworkStatus.offline);

      expect(statuses, [NetworkStatus.online, NetworkStatus.offline]);
      expect(harness.monitor.status, NetworkStatus.offline);

      await subscription.cancel();
      await harness.monitor.dispose();
    });
  });
}
