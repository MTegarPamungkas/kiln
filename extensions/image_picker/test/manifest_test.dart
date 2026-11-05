import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('image_picker manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.provides, ['media']);
    expect(manifest.optionalRequires, containsAll(<String>[
      'permission',
      'file_storage',
    ]));
    expect(manifest.dependencies, contains('image_picker'));
    expect(
      manifest.platformSetup.ios.plist,
      contains('NSCameraUsageDescription'),
    );
    expect(
      manifest.platformSetup.macos.entitlements,
      contains('com.apple.security.device.camera'),
    );
  });
}
