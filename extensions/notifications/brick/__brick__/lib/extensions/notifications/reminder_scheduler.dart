import 'package:kiln_core/kiln_core.dart';

import 'notification_id_allocator.dart';

typedef _ScheduledReminder = ({
  int id,
  String title,
  String body,
  DateTime when,
  String? channelId,
  String? payload,
});

/// Schedules reminders idempotently, keyed by a stable string.
final class ReminderScheduler {
  ReminderScheduler({
    required this.notifications,
    this.allocator = const NotificationIdAllocator(),
  });

  final Notifications notifications;
  final NotificationIdAllocator allocator;
  final Map<String, _ScheduledReminder> _scheduled =
      <String, _ScheduledReminder>{};

  Set<String> get scheduledKeys => _scheduled.keys.toSet();

  /// Schedules [key] when it changed, replacing the previous reminder.
  Future<bool> schedule({
    required String key,
    required String title,
    required String body,
    required DateTime when,
    String? channelId,
    String? payload,
  }) async {
    final id = allocator.idFor(key);
    final entry = (
      id: id,
      title: title,
      body: body,
      when: when,
      channelId: channelId,
      payload: payload,
    );
    if (_scheduled[key] == entry) {
      return false;
    }
    if (_scheduled.containsKey(key)) {
      await notifications.cancel(id);
    }
    await notifications.schedule(
      NotificationMessage(
        id: id,
        title: title,
        body: body,
        payload: payload,
        channelId: channelId,
      ),
      when,
    );
    _scheduled[key] = entry;
    return true;
  }

  Future<void> cancel(String key) async {
    if (_scheduled.remove(key) == null) {
      return;
    }
    await notifications.cancel(allocator.idFor(key));
  }

  Future<void> cancelAll() async {
    _scheduled.clear();
    await notifications.cancelAll();
  }
}
