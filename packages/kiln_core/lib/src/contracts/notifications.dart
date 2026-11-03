/// A notification to display or schedule.
final class NotificationMessage {
  const NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    this.channelId,
  });

  final int id;
  final String title;
  final String body;
  final String? payload;
  final String? channelId;
}

/// A notification the user tapped.
final class NotificationTap {
  const NotificationTap(this.payload);

  final String? payload;
}

/// Displays, schedules, and receives local notifications.
abstract interface class Notifications {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> show(NotificationMessage message);

  Future<void> schedule(NotificationMessage message, DateTime when);

  Future<void> cancel(int id);

  Future<void> cancelAll();

  Stream<NotificationTap> get taps;

  Future<void> dispose();
}
