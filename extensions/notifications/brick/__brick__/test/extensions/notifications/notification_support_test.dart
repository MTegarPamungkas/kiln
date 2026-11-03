import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/notifications/notification_gateway.dart';
import 'package:{{app_name}}/extensions/notifications/notification_support.dart';

final class _FakeGateway implements NotificationGateway {
  _FakeGateway({this.initializeError});

  final Object? initializeError;
  int initializeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    final error = initializeError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> show(NotificationRequest request) async {}

  @override
  Future<void> schedule(NotificationRequest request, DateTime when) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Stream<NotificationTap> get taps => const Stream<NotificationTap>.empty();

  @override
  String? get launchPayload => null;

  @override
  Future<void> dispose() async {}
}

void main() {
  test('reports supported when the gateway initializes', () async {
    final gateway = _FakeGateway();
    final support = NotificationSupport(gateway: gateway);

    final info = await support.check();

    expect(info.isSupported, isTrue);
    expect(gateway.initializeCalls, 1);
  });

  test('caches the probe result', () async {
    final gateway = _FakeGateway();
    final support = NotificationSupport(gateway: gateway);

    await support.check();
    await support.check();

    expect(gateway.initializeCalls, 1);
    support.clear();
    await support.check();
    expect(gateway.initializeCalls, 2);
  });

  test('maps a missing plugin to unsupported platform', () async {
    final support = NotificationSupport(
      gateway: _FakeGateway(initializeError: UnsupportedError('web')),
    );

    final info = await support.check();

    expect(info.state, SupportState.unsupportedPlatform);
    expect(info.toFailure().code, FailureCode.unsupportedPlatform);
  });

  test('maps other startup errors to unavailable', () async {
    final support = NotificationSupport(
      gateway: _FakeGateway(initializeError: StateError('broken service')),
    );

    final info = await support.check();

    expect(info.state, SupportState.unavailable);
    expect(info.toFailure().code, FailureCode.unavailable);
  });
}
