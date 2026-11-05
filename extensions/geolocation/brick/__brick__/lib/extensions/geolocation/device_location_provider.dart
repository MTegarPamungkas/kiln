import 'package:kiln_core/kiln_core.dart';

import 'geolocation_support.dart';
import 'location_gateway.dart';

/// [LocationProvider] backed by a LocationGateway and the optional Permissions
/// contract.
final class DeviceLocationProvider implements LocationProvider {
  const DeviceLocationProvider({required this.gateway, this.permissions});

  final LocationGateway gateway;
  final Permissions? permissions;

  @override
  Future<bool> isServiceEnabled() => gateway.isServiceEnabled();

  @override
  Future<GeoPosition> current({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    await _ensurePermission();
    return gateway.current(accuracy: accuracy);
  }

  @override
  Stream<GeoPosition> updates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = 0,
  }) async* {
    await _ensurePermission();
    yield* gateway.updates(
      accuracy: accuracy,
      distanceFilterMeters: distanceFilterMeters,
    );
  }

  Future<void> _ensurePermission() async {
    final support = await GeolocationSupport(
      gateway: gateway,
      permissions: permissions,
    ).check();
    if (support.isSupported) {
      return;
    }
    if (support.state == SupportState.permissionDenied) {
      final requested = await _requestPermission();
      if (requested) {
        return;
      }
      throw const SupportInfo.unsupported(
        SupportState.permissionDenied,
        message: 'Location permission was not granted.',
      ).toFailure();
    }
    throw support.toFailure();
  }

  Future<bool> _requestPermission() async {
    final contract = permissions;
    if (contract != null) {
      try {
        final status = await contract.request(PermissionKind.location);
        return status.isGranted;
      } on Failure {
        // Fall back to the plugin when the contract cannot answer.
      }
    }
    final state = await gateway.requestPermission();
    return state == LocationPermissionState.granted;
  }
}
