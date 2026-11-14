import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kiln_core/kiln_core.dart';

/// [PushTransport] backed by Firebase Cloud Messaging.
///
/// The token is registered on the backend through the [PushTargets]
/// capability; foreground messages are forwarded on [PushTransport.foreground]
/// and, when the `notifications` capability is installed, surfaced as local
/// notifications.
final class AppwritePushTransport implements PushTransport {
  AppwritePushTransport({
    required this.pushTargets,
    this.notifications,
  }) : _mapper = const _PushFailureMapper();

  final PushTargets pushTargets;
  final Notifications? notifications;
  final _PushFailureMapper _mapper;

  String? _token;
  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _foreground;
  final StreamController<PushEnvelope> _foregroundController =
      StreamController<PushEnvelope>.broadcast();
  bool _initialized = false;

  /// Initializes Firebase, mints the token, registers the push target, and
  /// starts listening for foreground messages and token rotation.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    try {
      await Firebase.initializeApp();
    } on Object catch (error, stackTrace) {
      throw _mapper.map(error, stackTrace: stackTrace);
    }
    _initialized = true;

    try {
      // getToken stays on the classic FCM registration token, which is the
      // identifier the Appwrite FCM provider delivers to (v17 deprecates it
      // in favour of the installation FID, which Appwrite cannot send to).
      // ignore: deprecated_member_use
      _token = await FirebaseMessaging.instance.getToken();
      if (_token != null) {
        await pushTargets.register(token: _token!);
      }
      // ignore: deprecated_member_use
      _tokenRefresh = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _token = token;
        unawaited(_registerSafely(token));
      });
      // v17 moved foreground delivery onto a static stream.
      _foreground = FirebaseMessaging.onMessage.listen((message) {
        final envelope = _envelopeFrom(message);
        if (!_foregroundController.isClosed) {
          _foregroundController.add(envelope);
        }
        unawaited(_display(envelope));
      });
    } on Object catch (error, stackTrace) {
      throw _mapper.map(error, stackTrace: stackTrace);
    }
  }

  Future<void> _registerSafely(String token) async {
    try {
      await pushTargets.register(token: token);
    } on Object {
      // A failed rotation is retried on the next token event; the transport
      // keeps working with the previous registration.
    }
  }

  Future<void> _display(PushEnvelope envelope) async {
    if (notifications == null || envelope.title == null) {
      return;
    }
    try {
      await notifications?.show(
        NotificationMessage(
          id: DateTime.now().millisecondsSinceEpoch % 2147483647,
          title: envelope.title!,
          body: envelope.body ?? '',
          payload: jsonEncode(envelope.data),
        ),
      );
    } on Object {
      // Displaying is best-effort; the foreground stream still carries the
      // envelope for the application.
    }
  }

  PushEnvelope _envelopeFrom(RemoteMessage message) {
    return PushEnvelope(
      title: message.notification?.title,
      body: message.notification?.body,
      data: Map<String, Object?>.from(message.data),
    );
  }

  @override
  Future<String?> token() async => _token;

  @override
  Stream<PushEnvelope> get foreground => _foregroundController.stream;

  @override
  Future<void> dispose() async {
    await _tokenRefresh?.cancel();
    await _foreground?.cancel();
    if (!_foregroundController.isClosed) {
      await _foregroundController.close();
    }
    _initialized = false;
  }
}

/// Maps Firebase transport errors to contract failures.
final class _PushFailureMapper {
  const _PushFailureMapper();

  Failure map(Object error, {StackTrace? stackTrace}) {
    if (error is Failure) {
      return error;
    }
    if (error is FirebaseException) {
      return Failure(
        code: FailureCode.unavailable,
        message: error.message ?? 'The push transport is unavailable.',
        kind: FailureKind.unavailable,
        cause: error,
        stackTrace: stackTrace,
        isRetryable: true,
        details: <String, Object?>{
          'plugin': error.plugin,
          'code': error.code,
        },
      );
    }
    return Failure(
      code: FailureCode.networkUnknown,
      message: error.toString(),
      kind: FailureKind.network,
      cause: error,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }
}
