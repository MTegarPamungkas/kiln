import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/notifications/notification_tap_hub.dart';

void main() {
  test('buffers taps during a gap between router listeners', () async {
    final hub = NotificationTapHub();
    final first = hub.taps.listen((_) {});
    await first.cancel();
    hub.add('/orders/42');
    final received = <String?>[];
    final second = hub.taps.listen((tap) => received.add(tap.payload));
    await Future<void>.delayed(Duration.zero);
    expect(received, ['/orders/42']);
    await second.cancel();
    await hub.dispose();
  });
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

    expect(taps.map((tap) => tap.payload), [
      'launch',
      'foreground',
      null,
      'manual',
    ]);

    await subscription.cancel();
    await hub.dispose();
    await foreground.close();
    await background.close();
  });

  test('replays launch and early taps to a late listener once', () async {
    final hub = NotificationTapHub(launchPayload: 'launch');

    await hub.start();
    hub.add('early');
    final first = <NotificationTap>[];
    final subscription = hub.taps.listen(first.add);

    // A synchronous broadcast controller cannot deliver from onListen.
    expect(first, isEmpty);
    hub.add('during-replay');
    await pumpEventQueue();

    expect(first.map((tap) => tap.payload), [
      'launch',
      'early',
      'during-replay',
    ]);

    await subscription.cancel();
    final second = <NotificationTap>[];
    final secondSubscription = hub.taps.listen(second.add);
    expect(second, isEmpty);

    hub.add('warm');
    expect(second.single.payload, 'warm');

    await secondSubscription.cancel();
    await hub.dispose();
  });

  test('disposing before replay does not emit or throw', () async {
    final hub = NotificationTapHub(launchPayload: 'launch');
    await hub.start();
    final taps = <NotificationTap>[];
    final subscription = hub.taps.listen(taps.add);
    final disposal = hub.dispose();
    await pumpEventQueue();
    expect(taps, isEmpty);
    await subscription.cancel();
    await disposal;
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
