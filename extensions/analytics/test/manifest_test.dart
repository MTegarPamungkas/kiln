import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('analytics manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.id, 'analytics');
    expect(manifest.category, 'analytics');
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, <String>['analytics']);
    expect(manifest.optionalRequires, <String>['flavor']);
    expect(manifest.dependencies, containsPair('posthog_flutter', '^5.58.3'));
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

    final apiKey = manifest.promptsByName['api_key'];
    expect(apiKey, isNotNull);
    expect(apiKey!.type.name, 'secret');
    expect(apiKey.required, isFalse);
    expect(apiKey.defaultValue, '');

    final host = manifest.promptsByName['host'];
    expect(host, isNotNull);
    expect(host!.type.name, 'url');
    expect(host.defaultValue, 'https://us.i.posthog.com');

    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
    expect(manifest.compatibility.dart, '>=3.9.0');
  });
}
