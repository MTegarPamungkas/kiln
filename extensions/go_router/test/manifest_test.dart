import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('go_router manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.id, 'go_router');
    expect(manifest.category, 'navigation');
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, <String>['navigation']);
    expect(manifest.optionalRequires, containsAll(<String>[
      'deep_links',
      'notifications',
      'analytics',
      'logger',
    ]));
    expect(manifest.dependencies, containsPair('go_router', '^18.1.2'));
    expect(manifest.slots, hasLength(1));
    expect(manifest.slots.single.name, 'router.routes');
    expect(manifest.slots.single.item, 'AppRoute');
    expect(manifest.platformSetup.platforms, containsAll(<String>[
      'android',
      'ios',
      'macos',
      'web',
      'windows',
      'linux',
    ]));
    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
    expect(manifest.compatibility.dart, '>=3.9.0');
  });
}
