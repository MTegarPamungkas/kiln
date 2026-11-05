import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('connectivity manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.provides, ['connectivity']);
    expect(manifest.optionalRequires, contains('http_pipeline'));
    expect(
      manifest.platformSetup.android.permissions,
      contains('android.permission.ACCESS_NETWORK_STATE'),
    );
  });
}
