import 'notifications.dart';

/// Optional push capability for notification taps, including a launch tap.
///
/// Implementations retain a launch tap until the first consumer subscribes.
/// Receiving a foreground message alone must not emit a tap.
abstract interface class PushNotificationOpens {
  Stream<NotificationTap> get notificationTaps;
}

/// What a transport's background delivery can rely on right now.
///
/// Platform-specific: a transport that cannot describe its background delivery
/// returns null from [PushDeliveryControls.status] instead of guessing.
final class PushDeliveryStatus {
  const PushDeliveryStatus({
    this.exactAlarms = false,
    this.ignoringBatteryOptimizations = false,
    this.foregroundService = false,
    this.bestEffort = true,
    this.backgroundRestricted = false,
  });

  /// Punctual background wake-ups are allowed (for example Android's
  /// `SCHEDULE_EXACT_ALARM` is granted).
  final bool exactAlarms;

  /// The application is exempt from battery optimisation.
  final bool ignoringBatteryOptimizations;

  /// A foreground service keeps the connection open (see
  /// [PushDeliveryControls.setForeground]).
  final bool foregroundService;

  /// Some messages may arrive late, or only when the app is opened again.
  final bool bestEffort;

  /// The user restricted background usage in the app's battery settings.
  final bool backgroundRestricted;

  @override
  String toString() =>
      'PushDeliveryStatus(exactAlarms: $exactAlarms, '
      'ignoringBatteryOptimizations: $ignoringBatteryOptimizations, '
      'foregroundService: $foregroundService, bestEffort: $bestEffort, '
      'backgroundRestricted: $backgroundRestricted)';
}

/// Optional push capability for keeping background delivery reliable.
///
/// Delivery while the application is closed is best effort on mobile: the
/// platform defers wake-ups, and the user can restrict background usage. These
/// calls let an application explain that and ask, instead of silently dropping
/// messages. Every call is a no-op on platforms without the concept.
abstract interface class PushDeliveryControls {
  /// The current background-delivery guarantees, or null when the transport
  /// cannot describe them.
  Future<PushDeliveryStatus?> status();

  /// Keeps the connection open in a foreground service (Android), for immediate
  /// delivery while the app is closed. Call it while the app is in the
  /// foreground; the platform refuses to start a service from the background.
  Future<void> setForeground(bool enabled);

  /// Opens the system screen that allows exact alarms (Android 12+). Call it
  /// from a user action. Resolves false when there is nothing to ask.
  Future<bool> requestExactAlarms();

  /// Asks for an exemption from battery optimisation. Call it from a user
  /// action. Resolves false when there is nothing to ask.
  Future<bool> requestIgnoreBatteryOptimizations();

  /// Retries a failed subscription immediately instead of waiting for the next
  /// backoff step, for example when the app notices connectivity returned.
  Future<void> retryNow();
}

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
