/// Appwrite Push transport settings rendered from the install prompts.
final class AppwritePushNativeConfig {
  const AppwritePushNativeConfig({
    this.pushEndpoint = '',
    this.notificationTitle = 'Notifications',
    this.background = true,
  });

  /// Values the Kiln installer writes into the application.
  static const defaults = AppwritePushNativeConfig(
    pushEndpoint: '{{{push_endpoint}}}',
    notificationTitle: '{{{notification_title}}}',
    background: {{background}},
  );

  /// MQTT broker endpoint such as `mqtts://push.example.com:8883`. Blank lets
  /// the SDK derive `push.<api host>`; self-hosted servers usually set it.
  final String pushEndpoint;

  /// Title the SDK shows on background notifications.
  final String notificationTitle;

  /// Whether the SDK keeps delivering (and posting notifications) while the
  /// app is backgrounded. Foreground delivery is independent.
  final bool background;
}
