import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('deep_link manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.provides, ['deep_links']);
    expect(manifest.exclusive, isTrue);
    expect(manifest.dependencies, contains('app_links'));

    final prompts = <String, PromptSpec>{
      for (final prompt in manifest.prompts) prompt.name: prompt,
    };
    expect(prompts['scheme']?.required, isTrue);
    expect(prompts['scheme']?.defaultValue, 'kiln');
    expect(prompts['hosts']?.type, PromptType.multi);
    expect(prompts['path_prefixes']?.type, PromptType.multi);

    expect(manifest.platformSetup.android.urlSchemes, ['kiln']);
    expect(manifest.platformSetup.android.appLinkHosts, contains('kiln.dev'));
    expect(manifest.platformSetup.ios.urlSchemes, ['kiln']);
    expect(
      manifest.platformSetup.ios.associatedDomains,
      contains('applinks:kiln.dev'),
    );
  });
}
