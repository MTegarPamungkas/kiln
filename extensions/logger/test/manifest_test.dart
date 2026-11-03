import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('logger manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.id, 'logger');
    expect(manifest.category, 'logging');
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, <String>['logger']);
    expect(
      manifest.optionalRequires,
      containsAll(<String>['crash_reporter', 'http_pipeline', 'flavor']),
    );
    expect(manifest.dependencies, contains('path_provider'));
    expect(
      manifest.promptsByName.keys,
      containsAll(<String>['file_sink', 'http_logging']),
    );
    expect(
      manifest.platformSetup.platforms,
      containsAll(<String>[
        'android',
        'ios',
        'macos',
        'web',
        'windows',
        'linux',
      ]),
    );
  });
}
