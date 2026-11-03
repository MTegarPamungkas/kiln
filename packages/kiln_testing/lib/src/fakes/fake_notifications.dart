import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// One scheduled notification recorded by [FakeNotifications].
final class NotificationSchedule {
  const NotificationSchedule(this.message, this.when);

  final NotificationMessage message;
  final DateTime when;
}

/// [Notifications] that records calls and emits taps on demand.
final class FakeNotifications implements Notifications {
  final List<NotificationMessage> shown = <NotificationMessage>[];
  final List<NotificationSchedule> scheduled = <NotificationSchedule>[];
  final List<int> cancelled = <int>[];
  final StreamController<NotificationTap> _taps =
      StreamController<NotificationTap>.broadcast(sync: true);

  bool initialized = false;
  bool permissionGranted = true;
  int cancelAllCalls = 0;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> show(NotificationMessage message) async {
    shown.add(message);
  }

  @override
  Future<void> schedule(NotificationMessage message, DateTime when) async {
    scheduled.add(NotificationSchedule(message, when));
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  Stream<NotificationTap> get taps => _taps.stream;

  void emitTap(String? payload) {
    _taps.add(NotificationTap(payload));
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _taps.close();
  }
}
