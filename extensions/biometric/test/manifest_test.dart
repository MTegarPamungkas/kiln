import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('biometric manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.provides, ['biometric']);
    expect(
      manifest.platformSetup.android.permissions,
      contains('android.permission.USE_BIOMETRIC'),
    );
    expect(manifest.platformSetup.android.activity, 'FlutterFragmentActivity');
    expect(
      manifest.platformSetup.ios.plist,
      contains('NSFaceIDUsageDescription'),
    );
    expect(manifest.platformSetup.platforms, isNot(contains('web')));
  });
}
