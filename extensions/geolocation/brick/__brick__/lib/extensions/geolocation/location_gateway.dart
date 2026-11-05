import 'package:kiln_core/kiln_core.dart';

/// Permission state reported by the platform location service.
enum LocationPermissionState {
  granted,
  denied,
  deniedForever,
  unableToDetermine,
}

/// Platform location access that can be faked in tests.
abstract interface class LocationGateway {
  Future<bool> isServiceEnabled();

  Future<LocationPermissionState> permission();

  Future<LocationPermissionState> requestPermission();

  Future<GeoPosition> current({required LocationAccuracy accuracy});

  Stream<GeoPosition> updates({
    required LocationAccuracy accuracy,
    required int distanceFilterMeters,
  });
}
