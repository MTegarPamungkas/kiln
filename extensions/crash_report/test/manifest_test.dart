import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('crash_report manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.id, 'crash_report');
    expect(manifest.category, 'crash');
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, <String>['crash_reporter']);
    expect(manifest.optionalRequires, <String>['flavor', 'http_pipeline']);
    expect(manifest.dependencies, containsPair('sentry_flutter', '^10.3.0'));
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

    final dsn = manifest.promptsByName['dsn'];
    expect(dsn, isNotNull);
    expect(dsn!.type.name, 'secret');
    expect(dsn.required, isFalse);
    expect(dsn.defaultValue, '');

    final release = manifest.promptsByName['release'];
    expect(release, isNotNull);
    expect(release!.type.name, 'string');
    expect(release.defaultValue, '');

    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
    expect(manifest.compatibility.dart, '>=3.9.0');
  });
}
