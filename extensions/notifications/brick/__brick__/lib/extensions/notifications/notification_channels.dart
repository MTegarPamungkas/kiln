import 'notifications_config.dart';

/// How strongly a channel surfaces its notifications.
enum NotificationImportance { low, normal, high }

/// One Android notification channel.
final class NotificationChannelSpec {
  const NotificationChannelSpec({
    required this.id,
    required this.name,
    this.description,
    this.importance = NotificationImportance.normal,
  });

  final String id;
  final String name;
  final String? description;
  final NotificationImportance importance;
}

/// The channels created when notifications start.
final class NotificationChannels {
  const NotificationChannels({required this.specs});

  factory NotificationChannels.defaults(NotificationsConfig config) {
    return NotificationChannels(
      specs: <NotificationChannelSpec>[
        NotificationChannelSpec(
          id: config.defaultChannelId,
          name: config.defaultChannelName,
          description: config.defaultChannelDescription,
          importance: NotificationImportance.high,
        ),
        NotificationChannelSpec(
          id: '${config.defaultChannelId}_reminders',
          name: 'Reminders',
          description: 'Scheduled reminders',
        ),
      ],
    );
  }

  final List<NotificationChannelSpec> specs;

  /// Resolves a requested channel, falling back to the default one.
  NotificationChannelSpec resolve(String? id) {
    if (id != null) {
      for (final spec in specs) {
        if (spec.id == id) {
          return spec;
        }
      }
    }
    return specs.first;
  }
}
