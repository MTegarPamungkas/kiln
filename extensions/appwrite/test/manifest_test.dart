import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('appwrite manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.category, 'auth');
    expect(manifest.tier, ExtensionTier.official);
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, <String>[
      'auth',
      'remote_database',
      'file_storage',
    ]);
    expect(manifest.optionalRequires, isEmpty);
    expect(manifest.dependencies, contains('appwrite'));
    expect(manifest.prompts.map((prompt) => prompt.name), <String>[
      'endpoint',
      'project_id',
      'database_id',
      'bucket_id',
    ]);
    expect(
      manifest.platformSetup.android.permissions,
      contains('android.permission.INTERNET'),
    );
    expect(manifest.platformSetup.supports('web'), isTrue);
    for (final step in manifest.manualSteps) {
      expect(step.id, matches(RegExp(r'^[a-z][a-z0-9_]*$')));
    }
    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
  });
}
