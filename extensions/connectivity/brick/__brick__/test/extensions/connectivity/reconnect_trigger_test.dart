import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/connectivity/reconnect_trigger.dart';

void main() {
  test('fires only on an offline to online transition', () {
    var reconnects = 0;
    final trigger = ReconnectTrigger(onReconnect: () => reconnects++);

    trigger.update(NetworkStatus.online);
    trigger.update(NetworkStatus.unknown);
    trigger.update(NetworkStatus.offline);
    trigger.update(NetworkStatus.offline);
    trigger.update(NetworkStatus.online);
    trigger.update(NetworkStatus.online);

    expect(reconnects, 1);
  });
}
