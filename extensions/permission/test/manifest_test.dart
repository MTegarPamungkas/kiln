import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('permission manifest is valid and exclusive', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, ['permission']);
    expect(manifest.prompts.single.name, 'kinds');
    expect(manifest.platformSetup.android.compileSdk, 37);
    expect(manifest.platformSetup.conditionals, isNotEmpty);
    final camera = manifest.platformSetup.conditionals.firstWhere(
      (conditional) => conditional.when['kinds'] == 'camera',
    );
    expect(camera.android.permissions, contains('android.permission.CAMERA'));
    expect(camera.ios.podfilePermissions, contains('PERMISSION_CAMERA'));
  });
}
