import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('supabase manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
  });

  test('supabase manifest declares capabilities and prompts', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(manifest.id, 'supabase');
    expect(manifest.category, 'auth');
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, <String>[
      'auth',
      'social_auth',
      'remote_database',
      'file_storage',
    ]);
    expect(manifest.optionalRequires, contains('deep_links'));
    expect(manifest.dependencies, contains('supabase_flutter'));

    final prompts = manifest.prompts.map((prompt) => prompt.name).toList();
    expect(prompts, containsAll(<String>['url', 'anon_key', 'schema']));

    final anonKey = manifest.prompts.firstWhere(
      (prompt) => prompt.name == 'anon_key',
    );
    expect(anonKey.secret, isTrue);
    expect(anonKey.required, isTrue);

    final schema = manifest.prompts.firstWhere(
      (prompt) => prompt.name == 'schema',
    );
    expect(schema.defaultValue, 'public');
  });

  test('supabase manifest configures the auth callback scheme', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(
      manifest.platformSetup.android.permissions,
      contains('android.permission.INTERNET'),
    );
    expect(manifest.platformSetup.android.urlSchemes, contains('kiln-auth'));
    expect(manifest.platformSetup.ios.urlSchemes, contains('kiln-auth'));
    expect(
      manifest.manualSteps.map((step) => step.id),
      containsAll(<String>[
        'configure_auth_redirect',
        'enable_realtime',
        'create_storage_bucket',
      ]),
    );
  });
}
