import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('rest_auth manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.provides, ['auth']);
    expect(
      manifest.requires,
      containsAll(<String>['http_client', 'secure_storage']),
    );
    expect(manifest.promptsByName.keys, contains('base_url'));
  });
}
