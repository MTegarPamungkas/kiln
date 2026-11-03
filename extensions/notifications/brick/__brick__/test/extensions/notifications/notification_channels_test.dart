import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/notifications/notification_channels.dart';
import 'package:{{app_name}}/extensions/notifications/notifications_config.dart';

void main() {
  test('defaults define the app channel and a reminders channel', () {
    final channels = NotificationChannels.defaults(
      const NotificationsConfig(defaultChannelId: 'app_alerts'),
    );

    expect(channels.specs, hasLength(2));
    expect(channels.specs.first.id, 'app_alerts');
    expect(channels.specs.first.importance, NotificationImportance.high);
    expect(channels.specs.last.id, 'app_alerts_reminders');
  });

  test('unknown channel ids fall back to the default', () {
    final channels = NotificationChannels.defaults(
      const NotificationsConfig(defaultChannelId: 'app_alerts'),
    );

    expect(channels.resolve('missing').id, 'app_alerts');
    expect(channels.resolve(null).id, 'app_alerts');
    expect(channels.resolve('app_alerts_reminders').name, 'Reminders');
  });
}
