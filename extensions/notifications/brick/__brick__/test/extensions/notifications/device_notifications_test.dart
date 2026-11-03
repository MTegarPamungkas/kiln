import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';

import 'test_support.dart';

void main() {
  test('initialize runs once and starts reporting taps', () async {
    final gateway = FakeNotificationGateway();
    final notifications = createDeviceNotifications(gateway: gateway);

    await notifications.initialize();
    await notifications.initialize();

    expect(gateway.initializeCalls, 1);
    expect(gateway.initialized, isTrue);
  });

  test('show uses the default channel and forwards the message', () async {
    final gateway = FakeNotificationGateway();
    final notifications = createDeviceNotifications(gateway: gateway);

    await notifications.show(
      const NotificationMessage(id: 7, title: 'Halo', body: 'Dunia'),
    );

    expect(gateway.shown, hasLength(1));
    expect(gateway.shown.single.id, 7);
    expect(gateway.shown.single.title, 'Halo');
    expect(gateway.shown.single.channelId, 'kiln_default');
  });

  test('schedule forwards the instant and payload', () async {
    final gateway = FakeNotificationGateway();
    final notifications = createDeviceNotifications(gateway: gateway);
    final when = DateTime.utc(2026, 11, 2, 9);

    await notifications.schedule(
      const NotificationMessage(
        id: 8,
        title: 'Pengingat',
        body: 'Minum air',
        payload: 'hydration',
      ),
      when,
    );

    expect(gateway.scheduled, hasLength(1));
    expect(gateway.scheduled.single.when, when);
    expect(gateway.scheduled.single.request.payload, 'hydration');
  });

  test('cancel and cancelAll reach the gateway', () async {
    final gateway = FakeNotificationGateway();
    final notifications = createDeviceNotifications(gateway: gateway);

    await notifications.cancel(3);
    await notifications.cancelAll();

    expect(gateway.cancelled, [3]);
    expect(gateway.cancelAllCalls, 1);
  });

  test('plugin errors become notification failures', () async {
    final gateway = FakeNotificationGateway()..failure = StateError('boom');
    final notifications = createDeviceNotifications(gateway: gateway);

    await expectLater(
      notifications.show(const NotificationMessage(id: 1, title: '', body: '')),
      throwsA(
        isA<Failure>()
            .having(
              (failure) => failure.code,
              'code',
              FailureCode.notificationsUnavailable,
            )
            .having(
              (failure) => failure.kind,
              'kind',
              FailureKind.notification,
            ),
      ),
    );
  });

  test('taps flow before initialize and after', () async {
    final gateway = FakeNotificationGateway();
    final notifications = createDeviceNotifications(gateway: gateway);
    final taps = <NotificationTap>[];
    final subscription = notifications.taps.listen(taps.add);

    gateway.emitTap('early');
    await notifications.initialize();
    gateway.emitTap('later');

    expect(taps.map((tap) => tap.payload), ['early', 'later']);

    await subscription.cancel();
    await notifications.dispose();
    expect(gateway.disposed, isTrue);
  });
}
