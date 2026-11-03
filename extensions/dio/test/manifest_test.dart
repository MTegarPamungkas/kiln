import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('extension.yaml is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(
      manifest.provides,
      containsAll(<String>['http_client', 'http_pipeline']),
    );
    expect(manifest.slots.single.name, 'http.interceptors');
  });
}
