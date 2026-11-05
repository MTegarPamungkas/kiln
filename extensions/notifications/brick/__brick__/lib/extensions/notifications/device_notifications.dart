import 'package:kiln_core/kiln_core.dart';

import 'notification_failure_mapper.dart';
import 'notification_gateway.dart';
import 'notification_permission_flow.dart';
import 'notification_tap_hub.dart';
import 'notifications_config.dart';

/// [Notifications] on top of a NotificationGateway.
final class DeviceNotifications implements Notifications {
  DeviceNotifications({
    required this.gateway,
    required this.tapHub,
    this.config = NotificationsConfig.defaults,
    required this.permissionFlow,
  });

  final NotificationGateway gateway;
  final NotificationTapHub tapHub;
  final NotificationPermissionFlow permissionFlow;
  final NotificationsConfig config;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await _guard(() async {
      await gateway.initialize();
      tapHub.setLaunchPayload(gateway.launchPayload);
      await tapHub.start();
    });
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() => _guard(permissionFlow.request);

  @override
  Future<void> show(NotificationMessage message) async {
    await _guard(() => gateway.show(_request(message)));
  }

  @override
  Future<void> schedule(NotificationMessage message, DateTime when) async {
    await _guard(() => gateway.schedule(_request(message), when));
  }

  @override
  Future<void> cancel(int id) => _guard(() => gateway.cancel(id));

  @override
  Future<void> cancelAll() => _guard(gateway.cancelAll);

  @override
  Stream<NotificationTap> get taps => tapHub.taps;

  @override
  Future<void> dispose() async {
    await tapHub.dispose();
    await gateway.dispose();
  }

  NotificationRequest _request(NotificationMessage message) {
    return NotificationRequest(
      id: message.id,
      title: message.title,
      body: message.body,
      payload: message.payload,
      channelId: message.channelId ?? config.defaultChannelId,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      throw mapNotificationError(error, stackTrace: stackTrace);
    }
  }
}
