import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('codegen manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.id, 'codegen');
    expect(manifest.category, 'codegen');
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, <String>['codegen']);
    expect(manifest.dependencies, containsPair('json_annotation', '^4.12.0'));
    expect(
      manifest.dependencies,
      containsPair('freezed_annotation', '^3.1.0'),
    );
    expect(
      manifest.devDependencies.keys,
      containsAll(<String>['build_runner', 'json_serializable', 'freezed']),
    );
    expect(manifest.platformSetup.platforms, <String>[
      'android',
      'ios',
      'macos',
      'web',
      'windows',
      'linux',
    ]);

    final generators = manifest.promptsByName['generators'];
    expect(generators, isNotNull);
    expect(generators!.isMulti, isTrue);
    expect(generators.options, <String>['json_serializable', 'freezed']);
    expect(generators.required, isTrue);

    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
    expect(manifest.compatibility.dart, '>=3.9.0');
  });
}
