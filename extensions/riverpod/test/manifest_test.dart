import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('riverpod manifest is valid and exclusive', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, ['state_riverpod']);
    expect(manifest.dependencies['flutter_riverpod'], isNotNull);
  });
}
