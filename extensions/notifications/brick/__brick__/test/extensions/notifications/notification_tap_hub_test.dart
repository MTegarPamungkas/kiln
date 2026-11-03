import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/notifications/notification_tap_hub.dart';

void main() {
  test('merges foreground, background, and the launch payload', () async {
    final foreground = StreamController<String?>.broadcast(sync: true);
    final background = StreamController<String?>.broadcast(sync: true);
    final hub = NotificationTapHub(
      foreground: foreground.stream,
      background: background.stream,
      launchPayload: 'launch',
    );
    final taps = <NotificationTap>[];
    final subscription = hub.taps.listen(taps.add);

    await hub.start();
    foreground.add('foreground');
    background.add(null);
    hub.add('manual');

    expect(
      taps.map((tap) => tap.payload),
      ['launch', 'foreground', null, 'manual'],
    );

    await subscription.cancel();
    await hub.dispose();
    await foreground.close();
    await background.close();
  });

  test('emits the launch payload only once', () async {
    final hub = NotificationTapHub(launchPayload: 'launch');
    final taps = <NotificationTap>[];
    final subscription = hub.taps.listen(taps.add);

    await hub.start();
    await hub.start();
    hub.setLaunchPayload('ignored');

    expect(taps, hasLength(1));

    await subscription.cancel();
    await hub.dispose();
  });
}
