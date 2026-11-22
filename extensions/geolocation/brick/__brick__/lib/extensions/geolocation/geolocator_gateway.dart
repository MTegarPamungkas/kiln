import 'dart:async';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:kiln_core/kiln_core.dart';

import 'geolocation_failure_mapper.dart';
import 'location_gateway.dart';

/// [LocationGateway] backed by geolocator.
final class GeolocatorGateway implements LocationGateway {
  const GeolocatorGateway();

  @override
  Future<bool> isServiceEnabled() => _guard(
    geo.Geolocator.isLocationServiceEnabled,
    message: 'Location services could not be checked.',
  );

  @override
  Future<LocationPermissionState> permission() => _guard(
    () async => _map(await geo.Geolocator.checkPermission()),
    message: 'Location permission could not be checked.',
  );

  @override
  Future<LocationPermissionState> requestPermission() => _guard(
    () async => _map(await geo.Geolocator.requestPermission()),
    message: 'Location permission could not be requested.',
  );

  @override
  Future<GeoPosition> current({required LocationAccuracy accuracy}) => _guard(
    () async {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: geo.LocationSettings(
          accuracy: _accuracy(accuracy),
          timeLimit: const Duration(seconds: 15),
        ),
      );
      return _position(position);
    },
    message: 'Location request failed.',
  );

  @override
  Stream<GeoPosition> updates({
    required LocationAccuracy accuracy,
    required int distanceFilterMeters,
  }) {
    if (distanceFilterMeters < 0) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'distanceFilterMeters cannot be negative.',
        kind: FailureKind.validation,
      );
    }
    return geo.Geolocator.getPositionStream(
      locationSettings: geo.LocationSettings(
        accuracy: _accuracy(accuracy),
        distanceFilter: distanceFilterMeters,
      ),
    ).map(_position).transform(
      StreamTransformer<GeoPosition, GeoPosition>.fromHandlers(
        handleError: (Object error, StackTrace stackTrace, EventSink<GeoPosition> sink) {
          sink.addError(
            mapGeolocationError(error, stackTrace: stackTrace),
            stackTrace,
          );
        },
      ),
    );
  }

  static Future<T> _guard<T>(
    Future<T> Function() action, {
    required String message,
  }) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw mapGeolocationError(
        error,
        stackTrace: stackTrace,
        message: message,
      );
    }
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
}

GeoPosition _position(geo.Position position) {
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
