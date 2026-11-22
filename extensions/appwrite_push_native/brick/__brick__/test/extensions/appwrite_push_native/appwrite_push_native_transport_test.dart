import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/appwrite_push_native/appwrite_push_native_transport.dart';

void main() {
  late _FakeDriver driver;
  late FakeAuthRepository auth;
  late AppwritePushNativeTransport transport;

  setUp(() async {
    driver = _FakeDriver();
    auth = FakeAuthRepository();
    await auth.signIn(email: auth.validEmail, password: auth.validPassword);
    transport = AppwritePushNativeTransport(auth: auth, driver: driver);
  });

  tearDown(() => transport.dispose());

  test('subscribes for the signed-in user on start', () async {
    await transport.start();

    expect(driver.subscribeCount, 1);
    expect(transport.isSubscribed, isTrue);
    expect(driver.lastBackground, isTrue);
    expect(driver.lastTitle, 'Notifications');
  });

  test(
    'logout fences messages while a subscription is still pending',
    () async {
      final gate = Completer<void>();
      driver.subscribeGate = gate;
      final received = <Object>[];
      final subscription = transport.foreground.listen(received.add);
      final starting = transport.start();
      await pumpEventQueue();
      await auth.signOut();
      driver.emit('{"notification":{"title":"old session"}}');
      await pumpEventQueue();
      expect(received, isEmpty);
      gate.complete();
      await starting;
      await pumpEventQueue();
      expect(transport.isSubscribed, isFalse);
      expect(driver.calls, contains('unsubscribe'));
      await subscription.cancel();
    },
  );

  test('unsubscribes on sign out and resubscribes on sign in', () async {
    await transport.start();

    await auth.signOut();
    await pumpEventQueue();
    expect(transport.isSubscribed, isFalse);
    expect(driver.calls, contains('close'));

    await auth.signIn(email: auth.validEmail, password: auth.validPassword);
    await pumpEventQueue();
    expect(driver.subscribeCount, 2);
    expect(transport.isSubscribed, isTrue);
  });

  test('maps foreground payloads to envelopes', () async {
    await transport.start();
    final received = transport.foreground.first;

    driver.emit(
      jsonEncode(<String, Object?>{
        'notification': <String, Object?>{'title': 'Kiln', 'body': 'Hello'},
        'data': <String, Object?>{'route': '/inbox'},
      }),
    );

    final envelope = await received;
    expect(envelope.title, 'Kiln');
    expect(envelope.body, 'Hello');
    expect(envelope.data['route'], '/inbox');
  });

  test('replays the initial tap to the first listener', () async {
    driver.initial = const AppwritePushOpened(
      topic: 'users/123',
      data: <String, Object?>{'route': '/sale'},
    );

    await transport.start();
    final opened = await transport.opened.first;

    expect(opened.topic, 'users/123');
    expect(opened.data['route'], '/sale');
  });

  test('generic tap source replays launch data without a backend-specific listener', () async {
    driver.initial = const AppwritePushOpened(
      topic: 'users/123',
      data: {'route': '/orders/42?tab=items'},
    );
    await transport.start();
    final tap = await transport.notificationTaps.first;
    expect(jsonDecode(tap.payload!), {'route': '/orders/42?tab=items'});
  });

  test('delivers taps while the app is running', () async {
    await transport.start();
    final opened = transport.opened.first;

    driver.emitTap(
      const AppwritePushOpened(
        topic: 'users/123',
        data: <String, Object?>{'route': '/chat'},
      ),
    );

    expect((await opened).data['route'], '/chat');
  });

  test('records a failed subscribe instead of throwing', () async {
    driver.subscribeError = StateError('broker offline');

    await transport.start();

    expect(transport.isSubscribed, isFalse);
    expect(transport.lastError, isA<StateError>());
  });

  test('dispose closes the driver', () async {
    await transport.start();

    await transport.dispose();

    expect(transport.isSubscribed, isFalse);
    expect(driver.closed, isTrue);
  });

  test('ignores a repeated tap on the same notification', () async {
    await transport.start();
    final taps = <AppwritePushOpened>[];
    final subscription = transport.opened.listen(taps.add);
    const opened = AppwritePushOpened(
      topic: 'users/123',
      messageId: 'msg-1',
      data: <String, Object?>{'route': '/orders/42'},
    );

    driver.emitTap(opened);
    driver.emitTap(opened);
    await pumpEventQueue();

    expect(taps, hasLength(1));
    expect(transport.duplicateTapsIgnored, 1);
    await subscription.cancel();
  });

  test('delivers a different notification in the same window', () async {
    await transport.start();
    final taps = <AppwritePushOpened>[];
    final subscription = transport.opened.listen(taps.add);

    driver.emitTap(
      const AppwritePushOpened(topic: 'users/123', messageId: 'msg-1'),
    );
    driver.emitTap(
      const AppwritePushOpened(topic: 'users/123', messageId: 'msg-2'),
    );
    await pumpEventQueue();

    expect(taps, hasLength(2));
    expect(transport.duplicateTapsIgnored, 0);
    await subscription.cancel();
  });

  test('does not replay a launch tap that the SDK reports again', () async {
    driver.initial = const AppwritePushOpened(
      topic: 'users/123',
      messageId: 'msg-launch',
      data: <String, Object?>{'route': '/sale'},
    );
    await transport.start();
    final taps = <AppwritePushOpened>[];
    final subscription = transport.opened.listen(taps.add);

    driver.emitTap(
      const AppwritePushOpened(
        topic: 'users/123',
        messageId: 'msg-launch',
        data: <String, Object?>{'route': '/sale'},
      ),
    );
    await pumpEventQueue();

    expect(taps, hasLength(1));
    expect(taps.single.data['route'], '/sale');
    expect(transport.duplicateTapsIgnored, 1);
    await subscription.cancel();
  });

  test('bounds start when the broker never acknowledges', () async {
    final gate = Completer<void>();
    driver.subscribeGate = gate;
    final bounded = AppwritePushNativeTransport(
      auth: auth,
      driver: driver,
      subscribeTimeout: const Duration(milliseconds: 50),
    );
    addTearDown(bounded.dispose);

    await bounded.start();

    expect(bounded.isSubscribed, isFalse);
    expect(bounded.lastError, isA<TimeoutException>());
    expect(bounded.pendingRetryDelay, isNotNull);
  });

  test('retries a failed subscription with exponential backoff', () async {
    driver.subscribeError = StateError('broker offline');
    final retrying = AppwritePushNativeTransport(
      auth: auth,
      driver: driver,
      retryBaseDelay: const Duration(milliseconds: 10),
      retryMaxDelay: const Duration(milliseconds: 20),
    );
    addTearDown(retrying.dispose);

    await retrying.start();
    expect(retrying.isSubscribed, isFalse);
    expect(retrying.pendingRetryDelay, const Duration(milliseconds: 10));

    driver.subscribeError = null;
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(retrying.isSubscribed, isTrue);
    expect(retrying.retryAttempt, 0);
    expect(retrying.pendingRetryDelay, isNull);
  });

  test('retryNow retries without waiting for the backoff', () async {
    driver.subscribeError = StateError('broker offline');
    final retrying = AppwritePushNativeTransport(
      auth: auth,
      driver: driver,
      retryBaseDelay: const Duration(minutes: 5),
      retryMaxDelay: const Duration(minutes: 5),
    );
    addTearDown(retrying.dispose);

    await retrying.start();
    expect(retrying.pendingRetryDelay, const Duration(minutes: 5));

    driver.subscribeError = null;
    await retrying.retryNow();

    expect(retrying.isSubscribed, isTrue);
    expect(retrying.pendingRetryDelay, isNull);
  });

  test('reports delivery state and forwards the reliability requests', () async {
    final controlled = _FakeDeliveryDriver();
    final controlledTransport = AppwritePushNativeTransport(
      auth: auth,
      driver: controlled,
    );
    addTearDown(controlledTransport.dispose);
    await controlledTransport.start();

    final status = await controlledTransport.status();
    expect(status, isNotNull);
    expect(status!.bestEffort, isTrue);
    expect(status.backgroundRestricted, isTrue);
    await controlledTransport.setForeground(true);
    expect(await controlledTransport.requestExactAlarms(), isTrue);
    expect(await controlledTransport.requestIgnoreBatteryOptimizations(), isTrue);
    expect(controlled.foreground, isTrue);
    expect(controlled.exactAlarmRequests, 1);
    expect(controlled.batteryRequests, 1);
  });

  test('reports no delivery state when the driver cannot describe it', () async {
    await transport.start();

    expect(await transport.status(), isNull);
    expect(await transport.requestExactAlarms(), isFalse);
    expect(await transport.requestIgnoreBatteryOptimizations(), isFalse);
    await transport.setForeground(true);
  });
}

class _FakeDriver implements AppwritePushDriver {
  final List<String> calls = <String>[];
  AppwritePushOpened? initial;
  Object? subscribeError;
  Completer<void>? subscribeGate;
  int subscribeCount = 0;
  bool closed = false;
  bool? lastBackground;
  String? lastTitle;
  void Function(String topic, String data)? _message;
  void Function(AppwritePushOpened opened)? _tap;

  @override
  Future<AppwritePushOpened?> getInitialNotification() async => initial;

  @override
  void Function() onNotificationOpened(
    void Function(AppwritePushOpened opened) callback,
  ) {
    _tap = callback;
    return () => _tap = null;
  }

  @override
  Future<AppwritePushSubscription> subscribe({
    required void Function(String topic, String data) onMessage,
    required bool background,
    required String title,
  }) async {
    calls.add('subscribe');
    subscribeCount++;
    closed = false;
    lastBackground = background;
    lastTitle = title;
    final error = subscribeError;
    if (error != null) {
      throw error;
    }
    _message = onMessage;
    await subscribeGate?.future;
    return _FakeSubscription(() => calls.add('unsubscribe'));
  }

  @override
  void close() {
    calls.add('close');
    closed = true;
    _message = null;
  }

  void emit(String payload) => _message?.call('users/123', payload);

  void emitTap(AppwritePushOpened opened) => _tap?.call(opened);
}

final class _FakeSubscription implements AppwritePushSubscription {
  _FakeSubscription(this._onUnsubscribe);

  final void Function() _onUnsubscribe;

  @override
  void unsubscribe() => _onUnsubscribe();
}

final class _FakeDeliveryDriver extends _FakeDriver
    implements AppwritePushDeliveryDriver {
  bool foreground = false;
  int exactAlarmRequests = 0;
  int batteryRequests = 0;

  @override
  Future<PushDeliveryStatus?> backgroundStatus() async =>
      const PushDeliveryStatus(bestEffort: true, backgroundRestricted: true);

  @override
  Future<void> setForeground(bool enabled) async {
    foreground = enabled;
  }

  @override
  Future<bool> requestExactAlarms() async {
    exactAlarmRequests++;
    return true;
  }

  @override
  Future<bool> requestIgnoreBatteryOptimizations() async {
    batteryRequests++;
    return true;
  }
}
