import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/connectivity/status_stabilizer.dart';

void main() {
  test('emits only the last status in the window', () async {
    final stabilizer = StatusStabilizer(
      window: const Duration(milliseconds: 20),
    );
    final emitted = <NetworkStatus>[];

    stabilizer.add(NetworkStatus.online, emitted.add);
    stabilizer.add(NetworkStatus.offline, emitted.add);

    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(emitted, [NetworkStatus.offline]);
    stabilizer.dispose();
  });
}
