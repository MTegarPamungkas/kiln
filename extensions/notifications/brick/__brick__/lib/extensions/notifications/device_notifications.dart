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
  bool _disposed = false;

  @override
  Future<void> initialize() async {
    if (_initialized || _disposed) {
      return;
    }
    await _guard(() async {
      await gateway.initialize();
      // Bootstrap can time out and dispose the module while the plugin is
      // starting; do not attach the tap hub afterwards.
      if (_disposed) {
        return;
      }
      tapHub.setLaunchPayload(gateway.launchPayload);
      await tapHub.start();
      if (_disposed) {
        return;
      }
      _initialized = true;
    });
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
    if (_disposed) {
      return;
    }
    _disposed = true;
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
