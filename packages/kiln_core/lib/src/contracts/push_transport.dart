/// A push message received by the device while the app was in the foreground.
final class PushEnvelope {
  const PushEnvelope({
    this.title,
    this.body,
    this.data = const <String, Object?>{},
  });

  /// Notification title, when the sender supplied one.
  final String? title;

  /// Notification body, when the sender supplied one.
  final String? body;

  /// Transport data payload (routing keys, ids, whatever the sender attached).
  final Map<String, Object?> data;
}

/// The device's push transport: token lifecycle and foreground delivery.
///
/// Registering the token on the backend is the [PushTargets] capability's
/// job; this contract exposes the transport side so applications can read the
/// token and react to messages that arrive while the app is foregrounded.
/// Background delivery is owned by the platform (system notification tray).
abstract interface class PushTransport {
  /// The current device token (FCM/APNs), or null when the transport is
  /// unavailable. Tokens rotate; [PushTargets.register] keeps the backend in
  /// sync.
  Future<String?> token();

  /// Messages received while the app is in the foreground.
  Stream<PushEnvelope> get foreground;

  /// Releases transport listeners.
  Future<void> dispose();
}
