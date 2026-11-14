import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:kiln_core/kiln_core.dart';

/// A background notification the user tapped, independent of the SDK model.
final class AppwritePushOpened {
  const AppwritePushOpened({
    required this.topic,
    this.data = const <String, Object?>{},
  });

  /// The topic the notification was published to.
  final String topic;

  /// The message's `data` payload, when it was a JSON object.
  final Map<String, Object?> data;
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

/// [PushTransport] over Appwrite Push (MQTT).
///
/// Appwrite Push has no device token: the transport subscribes to the signed-in
/// user's own topic through the shared Appwrite client, so messages reach every
/// device that user is signed in on. A session must exist before subscribing;
/// the transport follows [AuthRepository.authStateChanges] and subscribes and
/// unsubscribes as the session comes and goes, including when a different user
/// signs in on the same client.
final class AppwritePushNativeTransport implements PushTransport {
  AppwritePushNativeTransport({
    required this.auth,
    appwrite.Client? client,
    AppwritePushDriver? driver,
    this.pushEndpoint = '',
    this.notificationTitle = 'Notifications',
    this.background = true,
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
  int _generation = 0;
  bool _started = false;
  bool _closed = false;

  /// Messages received while the app is running.
  @override
  Stream<PushEnvelope> get foreground => _foreground.stream;

  /// Background notifications the user tapped, including the one that launched
  /// the app. A tap that arrives before anyone listens is replayed to the first
  /// listener.
  Stream<AppwritePushOpened> get opened => _opened.stream;

  /// Subscription failures that happened outside an awaited call, such as a
  /// broker that is unreachable when the session is restored.
  Stream<Object> get errors => _errors.stream;

  /// The last subscription failure, or null after a successful subscribe.
  Object? get lastError => _lastError;

  /// Whether a subscription is currently active.
  bool get isSubscribed => _subscription != null;

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
    _sessionTask = _sessionTask.then((_) async {
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
    }
  }

  Future<void> _subscribe(String userId) async {
    if (_closed || _subscription != null) {
      return;
    }
    final generation = _generation;
    final subscription = await _driver.subscribe(
      onMessage: _onMessage,
      background: background,
      title: notificationTitle,
    );
    if (_closed || generation != _generation) {
      subscription.unsubscribe();
      return;
    }
    _subscription = subscription;
    _subscribedUserId = userId;
    _lastError = null;
  }

  Future<void> _unsubscribe() async {
    _generation++;
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
    if (_opened.hasListener) {
      _opened.add(opened);
    } else {
      _pendingTap = opened;
    }
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
  Future<void> dispose() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _generation++;
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
final class SdkAppwritePushDriver implements AppwritePushDriver {
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
