import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('appwrite_push_native manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.id, 'appwrite_push_native');
    expect(manifest.category, 'notifications');
    expect(manifest.tier, ExtensionTier.official);
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, ['push_transport']);
    expect(manifest.requires, ['auth']);
    expect(manifest.optionalRequires, isEmpty);
    expect(manifest.dependencies, contains('appwrite'));
    expect(manifest.platformSetup.supports('android'), isTrue);
    expect(manifest.platformSetup.supports('ios'), isTrue);
    for (final step in manifest.manualSteps) {
      expect(step.id, matches(RegExp(r'^[a-z][a-z0-9_]*$')));
    }
    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
  });
}
