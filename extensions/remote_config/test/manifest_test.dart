import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('remote_config manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.id, 'remote_config');
    expect(manifest.category, 'config');
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, <String>['remote_config']);
    expect(manifest.optionalRequires, <String>['flavor']);
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

    final endpoint = manifest.promptsByName['endpoint'];
    expect(endpoint, isNotNull);
    expect(endpoint!.type.name, 'string');
    expect(endpoint.required, isFalse);
    expect(endpoint.defaultValue, '');

    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
    expect(manifest.compatibility.dart, '>=3.9.0');
  });
}
