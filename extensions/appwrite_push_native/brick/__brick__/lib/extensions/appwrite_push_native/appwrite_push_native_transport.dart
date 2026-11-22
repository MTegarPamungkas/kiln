import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:kiln_core/kiln_core.dart';

/// A background notification the user tapped, independent of the SDK model.
final class AppwritePushOpened {
  const AppwritePushOpened({
    required this.topic,
    this.data = const <String, Object?>{},
    this.messageId,
  });

  /// The topic the notification was published to.
  final String topic;

  /// The message's `data` payload, when it was a JSON object.
  final Map<String, Object?> data;

  /// The Appwrite Messaging message id, when the message was sent through
  /// Messaging. Used to recognise a repeated tap on the same notification.
  final String? messageId;
}

/// One live subscription created by [AppwritePushDriver].
abstract interface class AppwritePushSubscription {
  /// Drops this subscription.
  void unsubscribe();
}

/// The Appwrite Push operations the transport needs.
///
/// Kept injectable so the lifecycle (subscribe, rotate user, unsubscribe) can
/// be tested without an MQTT broker.
abstract interface class AppwritePushDriver {
  /// The background notification that launched the app, if any.
  Future<AppwritePushOpened?> getInitialNotification();

  /// Registers a callback for taps while the app is running.
  void Function() onNotificationOpened(
    void Function(AppwritePushOpened opened) callback,
  );

  /// Subscribes to the signed-in user's own topic.
  Future<AppwritePushSubscription> subscribe({
    required void Function(String topic, String data) onMessage,
    required bool background,
    required String title,
  });

  /// Closes the connection and drops every subscription.
  void close();
}

/// The optional Appwrite Push operations behind [PushDeliveryControls].
///
/// Kept separate from [AppwritePushDriver] so a test or alternative driver only
/// implements the delivery guarantees it can honour.
abstract interface class AppwritePushDeliveryDriver {
  /// What background delivery can rely on now, or null off Android.
  Future<PushDeliveryStatus?> backgroundStatus();

  /// Keeps delivery in a foreground service (Android). A no-op elsewhere.
  Future<void> setForeground(bool enabled);

  /// Opens the exact-alarm permission screen (Android 12+).
  Future<bool> requestExactAlarms();

  /// Asks for an exemption from battery optimisation (Android).
  Future<bool> requestIgnoreBatteryOptimizations();
}

/// [PushTransport] over Appwrite Push (MQTT).
///
/// Appwrite Push has no device token: the transport subscribes to the signed-in
/// user's own topic through the shared Appwrite client, so messages reach every
/// device that user is signed in on. A session must exist before subscribing;
/// the transport follows [AuthRepository.authStateChanges] and subscribes and
/// unsubscribes as the session comes and goes, including when a different user
/// signs in on the same client.
///
/// Delivery while the app is closed is best effort. The transport bounds
/// [start] with [subscribeTimeout] so an unreachable broker cannot stall
/// bootstrap, retries a failed subscription with exponential backoff, ignores a
/// repeated tap on the same notification within [tapDedupeWindow], and exposes
/// [PushDeliveryControls] for the Android battery/exact-alarm decisions.
final class AppwritePushNativeTransport
    implements PushTransport, PushNotificationOpens, PushDeliveryControls {
  AppwritePushNativeTransport({
    required this.auth,
    appwrite.Client? client,
    AppwritePushDriver? driver,
    this.pushEndpoint = '',
    this.notificationTitle = 'Notifications',
    this.background = true,
    this.subscribeTimeout = const Duration(seconds: 10),
    this.tapDedupeWindow = const Duration(seconds: 2),
    this.retryBaseDelay = const Duration(seconds: 2),
    this.retryMaxDelay = const Duration(minutes: 5),
  }) : assert(
         client != null || driver != null,
         'A client or an AppwritePushDriver is required.',
       ),
       client = client {
    final target = this.client;
    if (target != null && pushEndpoint.trim().isNotEmpty) {
      target.setPushEndpoint(pushEndpoint.trim());
    }
    _driver = driver ?? SdkAppwritePushDriver(target!);
  }

  /// Shared Appwrite client owned by the `appwrite` extension.
  final appwrite.Client? client;

  /// Session source that decides when the transport subscribes.
  final AuthRepository auth;

  /// MQTT broker endpoint, when the server does not use the SDK default.
  final String pushEndpoint;

  /// Title shown on background notifications.
  final String notificationTitle;

  /// Whether the SDK posts notifications and keeps delivering in the
  /// background. Turn it off for foreground-only delivery.
  final bool background;

  /// How long [start] waits for the first subscription before recording a
  /// timeout and retrying in the background. Bounds bootstrap against a broker
  /// that accepts the connection but never acknowledges the subscription.
  final Duration subscribeTimeout;

  /// Window in which a repeated tap on the same notification is ignored. Covers
  /// a double tap and the SDK reporting the launch tap twice.
  final Duration tapDedupeWindow;

  /// First delay after a failed subscription; doubled on every attempt with
  /// jitter-free exponential growth up to [retryMaxDelay].
  final Duration retryBaseDelay;

  /// Upper bound for the retry delay.
  final Duration retryMaxDelay;

  late final AppwritePushDriver _driver;

  final StreamController<PushEnvelope> _foreground =
      StreamController<PushEnvelope>.broadcast();
  late final StreamController<AppwritePushOpened> _opened =
      StreamController<AppwritePushOpened>.broadcast(
        onListen: () => _flushPendingTap(),
      );
  final StreamController<Object> _errors = StreamController<Object>.broadcast();

  StreamSubscription<AuthSession?>? _authChanges;
  AppwritePushSubscription? _subscription;
  Future<void> _sessionTask = Future<void>.value();
  void Function()? _stopTapListener;
  AppwritePushOpened? _pendingTap;
  Object? _lastError;
  String? _subscribedUserId;
  String? _requestedUserId;
  int _generation = 0;
  bool _started = false;
  bool _closed = false;
  Timer? _retryTimer;
  int _retryAttempt = 0;
  int _ignoredDuplicateTaps = 0;
  String? _lastTapKey;
  DateTime? _lastTapAt;

  /// Messages received while the app is running.
  @override
  Stream<PushEnvelope> get foreground => _foreground.stream;

  /// Background notifications the user tapped, including the one that launched
  /// the app. A tap that arrives before anyone listens is replayed to the first
  /// listener.
  Stream<AppwritePushOpened> get opened => _opened.stream;

  /// Generic route payload consumed by navigation integrations.
  @override
  Stream<NotificationTap> get notificationTaps =>
      opened.map((event) => NotificationTap(jsonEncode(event.data)));

  /// Subscription failures that happened outside an awaited call, such as a
  /// broker that is unreachable when the session is restored.
  Stream<Object> get errors => _errors.stream;

  /// The last subscription failure, or null after a successful subscribe.
  Object? get lastError => _lastError;

  /// Whether a subscription is currently active.
  bool get isSubscribed => _subscription != null;

  /// How many repeated taps on the same notification were ignored.
  int get duplicateTapsIgnored => _ignoredDuplicateTaps;

  /// How many subscriptions have failed since the last success.
  int get retryAttempt => _retryAttempt;

  /// The delay scheduled for the next retry, or null when none is pending.
  Duration? get pendingRetryDelay {
    final timer = _retryTimer;
    if (timer == null || !timer.isActive) {
      return null;
    }
    return _nextRetryDelay;
  }

  Duration? _nextRetryDelay;

  /// Reports the notification that launched the app and starts following the
  /// session and the user's own topic.
  Future<void> start() async {
    if (_started || _closed) {
      return;
    }
    _started = true;
    await _reportInitialTap();
    try {
      _stopTapListener = _driver.onNotificationOpened(_publishTap);
    } on Object {
      // Tap delivery is mobile-only; foreground delivery still works.
    }
    _authChanges = auth.authStateChanges.listen(_enqueueSession);
    final session = auth.currentSession;
    if (session != null) {
      _enqueueSession(session);
      await _sessionTask;
    }
  }

  /// Appwrite Push addresses users, not devices, so there is no token.
  @override
  Future<String?> token() async => null;

  void _enqueueSession(AuthSession? session) {
    if (_closed) return;
    if (session?.userId != _requestedUserId) {
      _requestedUserId = session?.userId;
      _generation++;
      _cancelRetry();
    }
    final generation = _generation;
    _sessionTask = _sessionTask.then((_) async {
      if (_closed || generation != _generation) return;
      try {
        await _handleSession(session);
      } on Object catch (error) {
        _recordError(error);
      }
    });
  }

  Future<void> _handleSession(AuthSession? session) async {
    if (_closed) {
      return;
    }
    if (session == null) {
      await _unsubscribe();
      return;
    }
    if (_subscription != null && _subscribedUserId == session.userId) {
      return;
    }
    // A different user signed in on the same client: drop the previous
    // subscription before opening one on the new user's topic.
    if (_subscription != null) {
      await _unsubscribe();
    }
    await _subscribeSafely(session.userId);
  }

  Future<void> _reportInitialTap() async {
    try {
      final opened = await _driver.getInitialNotification();
      if (opened != null) {
        _publishTap(opened);
      }
    } on Object {
      // No initial notification on this launch, or no platform support.
    }
  }

  Future<void> _subscribeSafely(String userId) async {
    try {
      await _subscribe(userId);
    } on Object catch (error) {
      _subscription = null;
      _subscribedUserId = null;
      _recordError(error);
      _scheduleRetry(userId);
    }
  }

  Future<void> _subscribe(String userId) async {
    if (_closed || _subscription != null) {
      return;
    }
    final generation = _generation;
    final pending = _driver.subscribe(
      onMessage: (topic, data) {
        if (!_closed &&
            generation == _generation &&
            auth.currentSession?.userId == userId) {
          _onMessage(topic, data);
        }
      },
      background: background,
      title: notificationTitle,
    );
    final AppwritePushSubscription subscription;
    try {
      subscription = await pending.timeout(subscribeTimeout);
    } on TimeoutException {
      // The broker never acknowledged. Drop the late subscription so a
      // connection completed after the timeout cannot leak.
      unawaited(
        pending.then<void>((late) {
          try {
            late.unsubscribe();
          } on Object {
            // The abandoned subscription is already gone.
          }
        }, onError: (Object _) {}),
      );
      throw TimeoutException(
        'Push subscribe did not finish within '
        '${subscribeTimeout.inMilliseconds}ms.',
        subscribeTimeout,
      );
    }
    if (_closed || generation != _generation) {
      subscription.unsubscribe();
      _driver.close();
      return;
    }
    _subscription = subscription;
    _subscribedUserId = userId;
    _lastError = null;
    _retryAttempt = 0;
    _cancelRetry();
  }

  void _scheduleRetry(String userId) {
    if (_closed) {
      return;
    }
    final generation = _generation;
    _cancelRetry();
    final delay = _retryDelayFor(_retryAttempt);
    _retryAttempt++;
    _nextRetryDelay = delay;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      _nextRetryDelay = null;
      if (_closed || generation != _generation) {
        return;
      }
      if (auth.currentSession?.userId != userId) {
        return;
      }
      _enqueueSession(auth.currentSession);
    });
  }

  Duration _retryDelayFor(int attempt) {
    final exponent = attempt < 0 ? 0 : (attempt > 20 ? 20 : attempt);
    final millis = retryBaseDelay.inMilliseconds * (1 << exponent);
    if (millis <= 0) {
      return retryBaseDelay;
    }
    return millis >= retryMaxDelay.inMilliseconds
        ? retryMaxDelay
        : Duration(milliseconds: millis);
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _nextRetryDelay = null;
  }

  /// Retries a failed subscription immediately instead of waiting for the next
  /// backoff step, for example when the app notices the network came back.
  @override
  Future<void> retryNow() async {
    if (_closed) {
      return;
    }
    _cancelRetry();
    _retryAttempt = 0;
    _enqueueSession(auth.currentSession);
    await _sessionTask;
  }

  Future<void> _unsubscribe() async {
    _cancelRetry();
    _subscribedUserId = null;
    final subscription = _subscription;
    _subscription = null;
    subscription?.unsubscribe();
    try {
      _driver.close();
    } on Object {
      // Closing an already closed connection is harmless.
    }
  }

  void _onMessage(String topic, String data) {
    if (_foreground.isClosed) {
      return;
    }
    _foreground.add(pushEnvelopeFromPayload(data));
  }

  void _publishTap(AppwritePushOpened opened) {
    if (_opened.isClosed) {
      return;
    }
    if (_isRepeatedTap(opened)) {
      _ignoredDuplicateTaps++;
      return;
    }
    if (_opened.hasListener) {
      _opened.add(opened);
    } else {
      _pendingTap = opened;
    }
  }

  /// Whether this is the same notification tapped again inside
  /// [tapDedupeWindow]. Identity is the Messaging id when the sender used
  /// Messaging, otherwise the topic and the exact payload.
  bool _isRepeatedTap(AppwritePushOpened opened) {
    final window = tapDedupeWindow;
    if (window <= Duration.zero) {
      return false;
    }
    final key = _tapKey(opened);
    final now = DateTime.now();
    final lastAt = _lastTapAt;
    final repeated = _lastTapKey == key &&
        lastAt != null &&
        now.difference(lastAt) < window;
    _lastTapKey = key;
    _lastTapAt = now;
    return repeated;
  }

  String _tapKey(AppwritePushOpened opened) {
    final messageId = opened.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      return 'id:$messageId';
    }
    String payload;
    try {
      payload = jsonEncode(opened.data);
    } on Object {
      payload = opened.data.toString();
    }
    return 'topic:${opened.topic}|$payload';
  }

  void _flushPendingTap() {
    final tapped = _pendingTap;
    if (tapped == null || _opened.isClosed || !_opened.hasListener) {
      return;
    }
    _pendingTap = null;
    _opened.add(tapped);
  }

  void _recordError(Object error) {
    _lastError = error;
    if (!_errors.isClosed) {
      _errors.add(error);
    }
  }

  @override
  Future<PushDeliveryStatus?> status() async {
    final Object driver = _driver;
    if (driver is! AppwritePushDeliveryDriver) {
      return null;
    }
    try {
      return await driver.backgroundStatus();
    } on Object catch (error) {
      _recordError(error);
      return null;
    }
  }

  @override
  Future<void> setForeground(bool enabled) async {
    final Object driver = _driver;
    if (driver is! AppwritePushDeliveryDriver) {
      return;
    }
    try {
      await driver.setForeground(enabled);
    } on Object catch (error) {
      _recordError(error);
    }
  }

  @override
  Future<bool> requestExactAlarms() async {
    final Object driver = _driver;
    if (driver is! AppwritePushDeliveryDriver) {
      return false;
    }
    try {
      return await driver.requestExactAlarms();
    } on Object catch (error) {
      _recordError(error);
      return false;
    }
  }

  @override
  Future<bool> requestIgnoreBatteryOptimizations() async {
    final Object driver = _driver;
    if (driver is! AppwritePushDeliveryDriver) {
      return false;
    }
    try {
      return await driver.requestIgnoreBatteryOptimizations();
    } on Object catch (error) {
      _recordError(error);
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _generation++;
    _cancelRetry();
    await _authChanges?.cancel();
    _authChanges = null;
    _stopTapListener?.call();
    _stopTapListener = null;
    final subscription = _subscription;
    _subscription = null;
    _subscribedUserId = null;
    subscription?.unsubscribe();
    try {
      _driver.close();
    } on Object {
      // Already closed.
    }
    await _foreground.close();
    await _opened.close();
    await _errors.close();
  }
}

/// Appwrite Push through the Flutter SDK (MQTT).
final class SdkAppwritePushDriver
    implements AppwritePushDriver, AppwritePushDeliveryDriver {
  SdkAppwritePushDriver(appwrite.Client client) : _push = appwrite.Push(client);

  final appwrite.Push _push;

  @override
  Future<AppwritePushOpened?> getInitialNotification() async {
    final opened = await _push.getInitialNotification();
    return opened == null ? null : _openedFrom(opened);
  }

  @override
  void Function() onNotificationOpened(
    void Function(AppwritePushOpened opened) callback,
  ) {
    return _push.onNotificationOpened(
      (opened) => callback(_openedFrom(opened)),
    );
  }

  @override
  Future<AppwritePushSubscription> subscribe({
    required void Function(String topic, String data) onMessage,
    required bool background,
    required String title,
  }) async {
    final subscription = await _push.subscribe(
      null,
      (message) => onMessage(message.topic, message.data),
      background: background,
      title: title,
    );
    return _SdkAppwritePushSubscription(subscription);
  }

  @override
  void close() => _push.close();

  @override
  Future<PushDeliveryStatus?> backgroundStatus() async {
    final status = await _push.backgroundStatus();
    if (status == null) {
      return null;
    }
    return PushDeliveryStatus(
      exactAlarms: status.exactAlarms,
      ignoringBatteryOptimizations: status.ignoringBatteryOptimizations,
      foregroundService: status.foregroundService,
      bestEffort: status.bestEffort,
      backgroundRestricted: status.backgroundRestricted,
    );
  }

  @override
  Future<void> setForeground(bool enabled) => _push.setForeground(enabled);

  @override
  Future<bool> requestExactAlarms() => _push.requestExactAlarms();

  @override
  Future<bool> requestIgnoreBatteryOptimizations() =>
      _push.requestIgnoreBatteryOptimizations();
}

final class _SdkAppwritePushSubscription implements AppwritePushSubscription {
  _SdkAppwritePushSubscription(this._subscription);

  final appwrite.PushSubscription _subscription;

  @override
  void unsubscribe() => _subscription.unsubscribe();
}

AppwritePushOpened _openedFrom(appwrite.PushNotificationOpened opened) {
  return AppwritePushOpened(
    topic: opened.topic,
    data: Map<String, Object?>.from(opened.data),
    messageId: opened.messageId,
  );
}

/// Maps an Appwrite Push message to a [PushEnvelope].
PushEnvelope pushEnvelopeFromMessage(appwrite.PushMessage message) =>
    pushEnvelopeFromPayload(message.data);

/// Maps a push payload (`{"notification": {"title", "body"}, "data": {...}}`)
/// to a [PushEnvelope].
PushEnvelope pushEnvelopeFromPayload(String payload) {
  String? title;
  String? body;
  var data = <String, Object?>{};
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map) {
      final notification = decoded['notification'];
      if (notification is Map) {
        title = _stringOrNull(notification['title']);
        body = _stringOrNull(notification['body']);
      }
      final values = decoded['data'];
      if (values is Map) {
        data = <String, Object?>{
          for (final entry in values.entries) '${entry.key}': entry.value,
        };
      }
    }
  } on Object {
    // Delivery still matters when the sender used a non-JSON payload.
  }
  return PushEnvelope(title: title, body: body, data: data);
}

String? _stringOrNull(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
