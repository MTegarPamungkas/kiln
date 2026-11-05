import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/geolocation/geolocation_module.dart';
import 'package:{{app_name}}/extensions/geolocation/geolocation_support.dart';
import 'package:{{app_name}}/extensions/geolocation/location_gateway.dart';

void main() {
  test('module registers the location provider and support', () {
    final registry = GetItRegistry();

    const GeolocationModule().register(registry);

    expect(registry.read<LocationProvider>(), isA<LocationProvider>());
    expect(registry.read<LocationGateway>(), isA<LocationGateway>());
    expect(registry.read<GeolocationSupport>(), isA<GeolocationSupport>());
  });
}
