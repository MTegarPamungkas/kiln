import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('social_login manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.provides, ['social_login']);
    expect(manifest.requires, contains('social_auth'));
    expect(manifest.dependencies, contains('google_sign_in'));
    expect(manifest.dependencies, contains('sign_in_with_apple'));
    expect(
      manifest.platformSetup.ios.entitlements,
      contains('com.apple.developer.applesignin'),
    );
  });
}
