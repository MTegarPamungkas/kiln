import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('theme manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.category, 'theme');
    expect(manifest.exclusive, isTrue);
    expect(manifest.provides, ['theme']);
    expect(manifest.tier, ExtensionTier.official);
    expect(manifest.dependencies, isEmpty);
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

    final prompts = <String, PromptSpec>{
      for (final prompt in manifest.prompts) prompt.name: prompt,
    };
    expect(prompts.keys, containsAll(<String>[
      'seed_color',
      'font_family',
      'corner_radius',
      'density',
    ]));
    expect(prompts['seed_color']?.defaultValue, '#0F766E');
    expect(prompts['font_family']?.defaultValue, '');
    expect(prompts['corner_radius']?.defaultValue, 14);
    expect(prompts['corner_radius']?.min, 0);
    expect(prompts['corner_radius']?.max, 40);
    expect(prompts['density']?.type, PromptType.enumValue);
    expect(prompts['density']?.defaultValue, 'comfortable');
    expect(prompts['density']?.options, <String>['comfortable', 'compact']);
    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
  });
}
