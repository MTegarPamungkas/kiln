import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/notifications/device_notifications.dart';
import 'package:{{app_name}}/extensions/notifications/notification_channels.dart';
import 'package:{{app_name}}/extensions/notifications/notification_support.dart';
import 'package:{{app_name}}/extensions/notifications/notifications_config.dart';
import 'package:{{app_name}}/extensions/notifications/notifications_module.dart';
import 'package:{{app_name}}/extensions/notifications/timezone_resolver.dart';

void main() {
  test('module registers the Notifications contract and config', () {
    final registry = GetItRegistry();

    const NotificationsModule().register(registry);

    expect(registry.read<Notifications>(), isA<DeviceNotifications>());
    expect(registry.read<NotificationsConfig>(), isA<NotificationsConfig>());
    expect(registry.read<NotificationChannels>().specs, isNotEmpty);
    expect(registry.read<TimezoneResolver>(), isA<TimezoneResolver>());
    expect(registry.read<NotificationSupport>(), isA<NotificationSupport>());
  });
}
