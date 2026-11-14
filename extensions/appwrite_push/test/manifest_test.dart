import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('appwrite_push manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.id, 'appwrite_push');
    expect(manifest.category, 'notifications');
    expect(manifest.tier, ExtensionTier.official);
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, ['push_transport']);
    expect(manifest.requires, ['push_targets']);
    expect(manifest.optionalRequires, ['notifications']);
    expect(manifest.dependencies, contains('firebase_core'));
    expect(manifest.dependencies, contains('firebase_messaging'));
    expect(manifest.platformSetup.supports('android'), isTrue);
    for (final step in manifest.manualSteps) {
      expect(step.id, matches(RegExp(r'^[a-z][a-z0-9_]*$')));
    }
    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
  });
}
