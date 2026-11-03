import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('geolocation manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.provides, ['location']);
    expect(manifest.optionalRequires, contains('permission'));
    expect(manifest.platformSetup.platforms, contains('android'));
    expect(manifest.platformSetup.platforms, isNot(contains('linux')));
    expect(
      manifest.platformSetup.android.permissions,
      contains('android.permission.ACCESS_FINE_LOCATION'),
    );
    expect(
      manifest.platformSetup.ios.plist,
      contains('NSLocationWhenInUseUsageDescription'),
    );
  });
}
