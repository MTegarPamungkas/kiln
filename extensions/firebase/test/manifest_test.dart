import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('firebase manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.id, 'firebase');
    expect(manifest.category, 'auth');
    expect(manifest.exclusive, isTrue);
    expect(
      manifest.provides,
      containsAll(<String>[
        'auth',
        'social_auth',
        'remote_database',
        'file_storage',
        'token_provider',
        'account_management',
      ]),
    );
    expect(manifest.dependencies, contains('firebase_core'));
    expect(manifest.dependencies, contains('firebase_auth'));
    expect(manifest.dependencies, contains('cloud_firestore'));
    expect(manifest.dependencies, contains('firebase_storage'));
    expect(
      manifest.manualSteps.map((step) => step.id),
      contains('firebase_flutterfire_configure'),
    );
    expect(
      manifest.prompts.map((prompt) => prompt.name),
      containsAll(<String>[
        'options_source',
        'firebase_options_path',
        'emulator_host',
        'use_emulator_in_development',
      ]),
    );
  });
}
