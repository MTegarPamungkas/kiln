import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('l10n manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.id, 'l10n');
    expect(manifest.category, 'l10n');
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, <String>['l10n']);
    expect(manifest.optionalRequires, <String>['storage']);
    expect(manifest.platformSetup.platforms, <String>[
      'android',
      'ios',
      'macos',
      'web',
      'windows',
      'linux',
    ]);
    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
  });

  test('l10n manifest dependency and prompts match the docs', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(manifest.dependencies['flutter_localizations'], <String, Object?>{
      'sdk': 'flutter',
    });
    expect(manifest.dependencies['intl'], '^0.20.3');

    final locales = manifest.prompts.firstWhere(
      (prompt) => prompt.name == 'locales',
    );
    final fallback = manifest.prompts.firstWhere(
      (prompt) => prompt.name == 'fallback_locale',
    );

    expect(locales.isMulti, isTrue);
    expect(locales.defaultValue, <String>['id', 'en']);
    expect(locales.options, <String>['id', 'en']);
    expect(fallback.defaultValue, 'id');
  });
}
