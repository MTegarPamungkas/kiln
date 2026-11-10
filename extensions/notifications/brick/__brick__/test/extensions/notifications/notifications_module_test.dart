import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/notifications/device_notifications.dart';
import 'package:{{app_name}}/extensions/notifications/notification_channels.dart';
import 'package:{{app_name}}/extensions/notifications/notification_support.dart';
import 'package:{{app_name}}/extensions/notifications/notifications_config.dart';
import 'package:{{app_name}}/extensions/notifications/notifications_module.dart';
import 'package:{{app_name}}/extensions/notifications/reminder_scheduler.dart';
import 'package:{{app_name}}/extensions/notifications/timezone_resolver.dart';

void main() {
  test('module disposes its tap hub and gateway', () async {
    final registry = GetItRegistry();
    final module = NotificationsModule();
    module.register(registry);
    final done = expectLater(
      registry.read<Notifications>().taps,
      emitsDone,
    );

    await module.dispose();
    await done;
  });

  test('module registers the Notifications contract and config', () {
    final registry = GetItRegistry();

    NotificationsModule().register(registry);

    expect(registry.read<Notifications>(), isA<DeviceNotifications>());
    expect(registry.read<NotificationsConfig>(), isA<NotificationsConfig>());
    expect(registry.read<NotificationChannels>().specs, isNotEmpty);
    expect(registry.read<TimezoneResolver>(), isA<TimezoneResolver>());
    expect(registry.read<NotificationSupport>(), isA<NotificationSupport>());
    expect(registry.read<ReminderScheduler>(), isA<ReminderScheduler>());
  });
}
