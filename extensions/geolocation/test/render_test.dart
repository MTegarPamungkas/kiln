import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('geolocation brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'geo_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/geolocation/geolocation_module.dart',
        'lib/extensions/geolocation/geolocation_support.dart',
        'lib/extensions/geolocation/location_gateway.dart',
        'lib/extensions/geolocation/geolocator_gateway.dart',
        'lib/extensions/geolocation/device_location_provider.dart',
        'test/extensions/geolocation/geolocation_test.dart',
        'test/extensions/geolocation/geolocation_module_test.dart',
      ]),
    );
    final module = files.firstWhere(
      (file) => file.relativePath.endsWith('geolocation_module.dart'),
    );
    expect(
      String.fromCharCodes(module.bytes),
      contains("provides => const <String>{'location'}"),
    );
  });
}
