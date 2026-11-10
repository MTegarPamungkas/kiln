import 'package:kiln_core/kiln_core.dart';

import 'device_notifications.dart';
import 'notification_channels.dart';
import 'notification_permission_flow.dart';
import 'notification_support.dart';
import 'notification_tap_hub.dart';
import 'notifications_config.dart';
import 'plugin_notification_gateway.dart';
import 'reminder_scheduler.dart';
import 'timezone_resolver.dart';

/// Registers Notifications, its channels, and the timezone resolver.
final class NotificationsModule extends KilnModule {
  NotificationsModule();

  DeviceNotifications? _notifications;

  @override
  String get id => 'notifications';

  @override
  Set<String> get provides => const <String>{'notifications'};

  @override
  Set<String> get optionalRequires => const <String>{'permission'};

  @override
  void register(Registry registry) {
    const config = NotificationsConfig.defaults;
    final channels = NotificationChannels.defaults(config);
    final timezones = TimezoneResolver();
    final gateway = PluginNotificationGateway(
      config: config,
      channels: channels,
      timezones: timezones,
    );
    final permissionFlow = NotificationPermissionFlow(
      gateway: gateway,
      permissions: registry.readOrNull<Permissions>(),
    );
    final tapHub = NotificationTapHub(
      foreground: gateway.taps.map((tap) => tap.payload),
    );
    final support = NotificationSupport(gateway: gateway);
    final notifications = DeviceNotifications(
      gateway: gateway,
      tapHub: tapHub,
      config: config,
      permissionFlow: permissionFlow,
    );

    _notifications = notifications;
    registry
      ..registerSingleton<NotificationsConfig>(config)
      ..registerSingleton<NotificationChannels>(channels)
      ..registerSingleton<TimezoneResolver>(timezones)
      ..registerSingleton<NotificationSupport>(support)
      ..registerSingleton<Notifications>(notifications)
      ..registerSingleton<ReminderScheduler>(
        ReminderScheduler(notifications: notifications),
      );
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<NotificationSupport>().check();
  }

  @override
  Future<void> dispose() async {
    final notifications = _notifications;
    _notifications = null;
    await notifications?.dispose();
  }

  @override
  Future<void> ready(Registry registry) async {
    try {
      await registry.read<TimezoneResolver>().configure();
    } on Object {
      // Scheduling falls back to UTC when the device timezone is unknown.
    }
    try {
      await registry.read<Notifications>().initialize();
    } on Object catch (error) {
      registry.readOrNull<SupportRegistry>()?.record(
        id,
        SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'Local notifications could not start: $error',
          details: <String, Object?>{'error': '$error'},
        ),
      );
    }
  }
}
