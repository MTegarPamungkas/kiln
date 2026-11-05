import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('http_cache manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(
      manifest.requires,
      containsAll(<String>['http_client', 'http_pipeline']),
    );
    expect(manifest.optionalRequires, contains('storage'));
    expect(manifest.contributions.single.priority, 30);
  });
}
