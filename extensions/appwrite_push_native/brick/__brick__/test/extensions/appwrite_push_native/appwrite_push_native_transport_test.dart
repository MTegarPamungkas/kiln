import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
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
        'notification': <String, Object?>{
          'title': 'Kiln',
          'body': 'Hello',
        },
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
}

final class _FakeDriver implements AppwritePushDriver {
  final List<String> calls = <String>[];
  AppwritePushOpened? initial;
  Object? subscribeError;
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
