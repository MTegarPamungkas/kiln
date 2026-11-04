import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/geolocation/device_location_provider.dart';
import 'package:{{app_name}}/extensions/geolocation/geolocation_support.dart';
import 'package:{{app_name}}/extensions/geolocation/location_gateway.dart';

final class _FakeGateway implements LocationGateway {
  bool serviceEnabled = true;
  LocationPermissionState permissionState = LocationPermissionState.granted;
  LocationPermissionState requestResult = LocationPermissionState.granted;
  Object? probeError;
  GeoPosition? position;
  final StreamController<GeoPosition> controller =
      StreamController<GeoPosition>.broadcast(sync: true);

  @override
  Future<bool> isServiceEnabled() async {
    final error = probeError;
    if (error != null) {
      throw error;
    }
    return serviceEnabled;
  }

  @override
  Future<LocationPermissionState> permission() async => permissionState;

  @override
  Future<LocationPermissionState> requestPermission() async {
    permissionState = requestResult;
    return requestResult;
  }

  @override
  Future<GeoPosition> current({required LocationAccuracy accuracy}) async {
    return position!;
  }

  @override
  Stream<GeoPosition> updates({
    required LocationAccuracy accuracy,
    required int distanceFilterMeters,
  }) {
    return controller.stream;
  }
}

GeoPosition _position() {
  return GeoPosition(
    latitude: -6.2,
    longitude: 106.8,
    timestamp: DateTime.utc(2026, 11, 4),
  );
}

void main() {
  test('reports supported when service and permission are ready', () async {
    final gateway = _FakeGateway();
    final info = await GeolocationSupport(gateway: gateway).check();

    expect(info.isSupported, isTrue);
  });

  test('reports disabled location services', () async {
    final gateway = _FakeGateway()..serviceEnabled = false;
    final info = await GeolocationSupport(gateway: gateway).check();

    expect(info.state, SupportState.unavailable);
  });

  test('reports missing permission', () async {
    final gateway = _FakeGateway()
      ..permissionState = LocationPermissionState.denied;
    final info = await GeolocationSupport(gateway: gateway).check();

    expect(info.state, SupportState.permissionDenied);
  });

  test('maps a missing plugin to unsupported platform', () async {
    final gateway = _FakeGateway()
      ..probeError = MissingPluginException('no gps');
    final info = await GeolocationSupport(gateway: gateway).check();

    expect(info.state, SupportState.unsupportedPlatform);
  });

  test('requests permission before reading a position', () async {
    final gateway = _FakeGateway()
      ..permissionState = LocationPermissionState.denied
      ..requestResult = LocationPermissionState.granted
      ..position = _position();
    final provider = DeviceLocationProvider(gateway: gateway);

    final result = await provider.current();

    expect(result.latitude, -6.2);
    expect(gateway.permissionState, LocationPermissionState.granted);
  });

  test('throws a permission failure when the request is denied', () async {
    final gateway = _FakeGateway()
      ..permissionState = LocationPermissionState.denied
      ..requestResult = LocationPermissionState.deniedForever
      ..position = _position();
    final provider = DeviceLocationProvider(gateway: gateway);

    await expectLater(
      provider.current(),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.permissionDenied,
        ),
      ),
    );
  });

  test('isServiceEnabled reflects the gateway', () async {
    final gateway = _FakeGateway()..serviceEnabled = false;
    final provider = DeviceLocationProvider(gateway: gateway);

    expect(await provider.isServiceEnabled(), isFalse);
  });

  test('updates streams positions once permission is ready', () async {
    final gateway = _FakeGateway();
    final provider = DeviceLocationProvider(gateway: gateway);
    final received = <GeoPosition>[];
    final subscription = provider.updates().listen(received.add);

    await Future<void>.delayed(const Duration(milliseconds: 5));
    gateway.controller.add(_position());
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(received, hasLength(1));
    await subscription.cancel();
    await gateway.controller.close();
  });
}
