import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('calendar manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.provides, ['calendar']);
    expect(manifest.platformSetup.platforms, ['android', 'ios']);
    expect(
      manifest.platformSetup.ios.plist,
      contains('NSCalendarsUsageDescription'),
    );
  });
}
