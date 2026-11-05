import 'dart:async';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:kiln_core/kiln_core.dart';

import 'location_gateway.dart';

/// [LocationGateway] backed by geolocator.
final class GeolocatorGateway implements LocationGateway {
  const GeolocatorGateway();

  @override
  Future<bool> isServiceEnabled() => geo.Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermissionState> permission() async {
    return _map(await geo.Geolocator.checkPermission());
  }

  @override
  Future<LocationPermissionState> requestPermission() async {
    return _map(await geo.Geolocator.requestPermission());
  }

  @override
  Future<GeoPosition> current({required LocationAccuracy accuracy}) async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: geo.LocationSettings(
          accuracy: _accuracy(accuracy),
          timeLimit: const Duration(seconds: 15),
        ),
      );
      return _position(position);
    } on TimeoutException catch (error, stackTrace) {
      throw Failure(
        code: FailureCode.unavailable,
        message: 'Location request timed out.',
        kind: FailureKind.unavailable,
        cause: error,
        stackTrace: stackTrace,
        isRetryable: true,
      );
    }
  }

  @override
  Stream<GeoPosition> updates({
    required LocationAccuracy accuracy,
    required int distanceFilterMeters,
  }) {
    return geo.Geolocator.getPositionStream(
      locationSettings: geo.LocationSettings(
        accuracy: _accuracy(accuracy),
        distanceFilter: distanceFilterMeters,
      ),
    ).map(_position);
  }

  static geo.LocationAccuracy _accuracy(LocationAccuracy accuracy) {
    return switch (accuracy) {
      LocationAccuracy.lowest => geo.LocationAccuracy.lowest,
      LocationAccuracy.low => geo.LocationAccuracy.low,
      LocationAccuracy.medium => geo.LocationAccuracy.medium,
      LocationAccuracy.high => geo.LocationAccuracy.high,
      LocationAccuracy.best => geo.LocationAccuracy.best,
    };
  }

  static LocationPermissionState _map(geo.LocationPermission permission) {
    return switch (permission) {
      geo.LocationPermission.always ||
      geo.LocationPermission.whileInUse => LocationPermissionState.granted,
      geo.LocationPermission.denied => LocationPermissionState.denied,
      geo.LocationPermission.deniedForever =>
        LocationPermissionState.deniedForever,
      geo.LocationPermission.unableToDetermine =>
        LocationPermissionState.unableToDetermine,
    };
  }

  static GeoPosition _position(geo.Position position) {
    return GeoPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      accuracyMeters: position.accuracy,
      altitudeMeters: position.altitude,
      headingDegrees: position.heading,
      speedMetersPerSecond: position.speed,
    );
  }
}
