/// Notification settings from the install prompts.
final class NotificationsConfig {
  const NotificationsConfig({
    this.defaultChannelId = 'kiln_default',
    this.defaultChannelName = 'Notifications',
    this.defaultChannelDescription = 'App notifications',
    this.smallIcon = '@mipmap/ic_launcher',
    this.exactAlarms = false,
  });

  static const defaults = NotificationsConfig(
    defaultChannelId: '{{{default_channel}}}',
    smallIcon: '{{{small_icon}}}',
    exactAlarms: {{exact_alarms}},
  );

  final String defaultChannelId;
  final String defaultChannelName;
  final String defaultChannelDescription;
  final String smallIcon;
  final bool exactAlarms;
}
