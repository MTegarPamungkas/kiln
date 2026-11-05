import 'package:kiln_core/kiln_core.dart';

import 'device_location_provider.dart';
import 'geolocation_support.dart';
import 'geolocator_gateway.dart';
import 'location_gateway.dart';

/// Registers the device location provider and its support probe.
final class GeolocationModule extends KilnModule {
  const GeolocationModule();

  @override
  String get id => 'geolocation';

  @override
  Set<String> get platforms => const <String>{
    'android',
    'ios',
    'macos',
    'web',
    'windows',
  };

  @override
  Set<String> get provides => const <String>{'location'};

  @override
  Set<String> get optionalRequires => const <String>{'permission'};

  @override
  void register(Registry registry) {
    const gateway = GeolocatorGateway();
    final permissions = registry.readOrNull<Permissions>();
    final provider = DeviceLocationProvider(
      gateway: gateway,
      permissions: permissions,
    );
    registry
      ..registerSingleton<LocationGateway>(gateway)
      ..registerSingleton<LocationProvider>(provider)
      ..registerSingleton<GeolocationSupport>(
        GeolocationSupport(gateway: gateway, permissions: permissions),
      );
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<GeolocationSupport>().check();
  }
}
