import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/notifications/device_notifications.dart';
import 'package:{{app_name}}/extensions/notifications/notification_gateway.dart';
import 'package:{{app_name}}/extensions/notifications/notification_permission_flow.dart';
import 'package:{{app_name}}/extensions/notifications/notification_tap_hub.dart';
import 'package:{{app_name}}/extensions/notifications/notifications_config.dart';

final class FakeNotificationGateway implements NotificationGateway {
  final List<NotificationRequest> shown = <NotificationRequest>[];
  final List<({NotificationRequest request, DateTime when})> scheduled =
      <({NotificationRequest request, DateTime when})>[];
  final List<int> cancelled = <int>[];
  final StreamController<NotificationTap> _taps =
      StreamController<NotificationTap>.broadcast(sync: true);

  bool initialized = false;
  int initializeCalls = 0;
  bool permissionResult = true;
  int permissionCalls = 0;
  int cancelAllCalls = 0;
  bool disposed = false;
  Object? failure;
  String? launch;

  @override
  Stream<NotificationTap> get taps => _taps.stream;

  @override
  String? get launchPayload => launch;

  @override
  Future<void> initialize() async {
    await _maybeFail();
    initializeCalls++;
    initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _maybeFail();
    permissionCalls++;
    return permissionResult;
  }

  @override
  Future<void> show(NotificationRequest request) async {
    await _maybeFail();
    shown.add(request);
  }

  @override
  Future<void> schedule(NotificationRequest request, DateTime when) async {
    await _maybeFail();
    scheduled.add((request: request, when: when));
  }

  @override
  Future<void> cancel(int id) async {
    await _maybeFail();
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    await _maybeFail();
    cancelAllCalls++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _taps.close();
  }

  void emitTap(String? payload) {
    _taps.add(NotificationTap(payload));
  }

  Future<void> _maybeFail() async {
    final error = failure;
    if (error != null) {
      throw error;
    }
  }
}

DeviceNotifications createDeviceNotifications({
  FakeNotificationGateway? gateway,
  NotificationsConfig config = const NotificationsConfig(),
  Permissions? permissions,
}) {
  final effectiveGateway = gateway ?? FakeNotificationGateway();
  return DeviceNotifications(
    gateway: effectiveGateway,
    tapHub: NotificationTapHub(
      foreground: effectiveGateway.taps.map((tap) => tap.payload),
    ),
    config: config,
    permissionFlow: NotificationPermissionFlow(
      gateway: effectiveGateway,
      permissions: permissions,
    ),
  );
}
