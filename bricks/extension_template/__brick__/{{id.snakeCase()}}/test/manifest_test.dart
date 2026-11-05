import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
    );
    expect(const ManifestValidator().validate(manifest), isEmpty);
  });
}
