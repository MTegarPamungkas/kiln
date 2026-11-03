import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef NotificationsContractFactory =
    ({Notifications notifications, void Function(String? payload) emitTap})
    Function();

/// Behavior every [Notifications] implementation must share.
void notificationsContract({
  required NotificationsContractFactory create,
  String description = 'Notifications',
}) {
  group('$description contract', () {
    test(
      'initialize, show, schedule, cancel, and cancelAll complete',
      () async {
        final harness = create();
        final notifications = harness.notifications;
        const message = NotificationMessage(
          id: 1,
          title: 'Hello',
          body: 'World',
          payload: 'home',
        );

        await notifications.initialize();
        expect(await notifications.requestPermission(), isA<bool>());
        await notifications.show(message);
        await notifications.schedule(message, DateTime.utc(2026, 11, 2));
        await notifications.cancel(1);
        await notifications.cancelAll();
      },
    );

    test('taps reach the stream', () async {
      final harness = create();
      final taps = <NotificationTap>[];
      final subscription = harness.notifications.taps.listen(taps.add);

      harness.emitTap('profile');

      expect(taps, hasLength(1));
      expect(taps.single.payload, 'profile');

      await subscription.cancel();
      await harness.notifications.dispose();
    });
  });
}
