import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('neon manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.id, 'neon');
    expect(manifest.category, 'database');
    expect(manifest.exclusive, isFalse);
    expect(manifest.provides, <String>['remote_database']);
    expect(manifest.optionalRequires, isEmpty);
    expect(manifest.dependencies, containsPair('http', '^1.6.0'));
    expect(manifest.platformSetup.android.permissions, <String>[
      'android.permission.INTERNET',
    ]);
    expect(manifest.platformSetup.platforms, <String>[
      'android',
      'ios',
      'macos',
      'web',
      'windows',
      'linux',
    ]);
    expect(manifest.manualSteps, hasLength(2));

    final url = manifest.promptsByName['data_api_url'];
    expect(url, isNotNull);
    expect(url!.type.name, 'url');
    expect(url.required, isTrue);

    final apiKey = manifest.promptsByName['api_key'];
    expect(apiKey, isNotNull);
    expect(apiKey!.type.name, 'secret');
    expect(apiKey.secret, isTrue);

    final schema = manifest.promptsByName['schema'];
    expect(schema, isNotNull);
    expect(schema!.type.name, 'string');
    expect(schema.defaultValue, 'public');

    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
    expect(manifest.compatibility.dart, '>=3.9.0');
  });
}
