import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('theme brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'brand_app'});
    final paths = files.map((file) => file.relativePath).toList();

    expect(
      paths,
      containsAll(<String>[
        'lib/extensions/theme/theme_module.dart',
        'lib/extensions/theme/brand_theme.dart',
        'lib/extensions/theme/theme_config.dart',
        'lib/extensions/theme/color_schemes.dart',
        'lib/extensions/theme/text_styles.dart',
        'lib/extensions/theme/component_themes.dart',
        'lib/extensions/theme/design_tokens.dart',
        'lib/extensions/theme/semantic_colors.dart',
        'lib/extensions/theme/system_ui_style.dart',
        'lib/extensions/theme/theme_mode_controller.dart',
        'lib/extensions/theme/theme_mode_store.dart',
        'lib/extensions/theme/theme_context_x.dart',
        'test/extensions/theme/brand_theme_test.dart',
        'test/extensions/theme/theme_module_test.dart',
        'test/extensions/theme/theme_config_test.dart',
        'test/extensions/theme/color_schemes_test.dart',
        'test/extensions/theme/component_themes_test.dart',
        'test/extensions/theme/design_tokens_test.dart',
        'test/extensions/theme/semantic_colors_test.dart',
        'test/extensions/theme/theme_mode_controller_test.dart',
        'test/extensions/theme/theme_mode_store_test.dart',
        'test/extensions/theme/contrast_test.dart',
        'test/extensions/theme/theme_golden_test.dart',
        'test/extensions/theme/goldens/theme_swatches.png',
      ]),
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('theme_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains("themeSeedColor('#0F766E')"));
    expect(source, contains("themeFontFamily('')"));
    expect(source, contains('cornerRadius: 14'));
    expect(source, contains('density: ThemeDensity.comfortable'));

    final configGolden = File(
      'test/goldens/rendered/lib/extensions/theme/theme_config.dart.golden',
    );
    if (Platform.environment['UPDATE_GOLDENS'] == '1') {
      await configGolden.parent.create(recursive: true);
      await configGolden.writeAsString(source);
    }
    expect(source, configGolden.readAsStringSync());

    final module = files.firstWhere(
      (file) => file.relativePath.endsWith('theme_module.dart'),
    );
    expect(
      String.fromCharCodes(module.bytes),
      contains("import 'package:brand_app/core/theme/app_theme_config.dart';"),
    );

    final golden = files.firstWhere(
      (file) => file.relativePath.endsWith('goldens/theme_swatches.png'),
    );
    final reference = File(
      'brick/__brick__/test/extensions/theme/goldens/theme_swatches.png',
    ).readAsBytesSync();
    expect(golden.bytes, reference);
  });

  test('theme brick renders custom prompt answers', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(
      project: const {'name': 'custom_app'},
      answers: const <String, Object?>{
        'seed_color': '#1D4ED8',
        'font_family': 'Inter',
        'corner_radius': 22,
        'density': 'compact',
      },
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('theme_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains("themeSeedColor('#1D4ED8')"));
    expect(source, contains("themeFontFamily('Inter')"));
    expect(source, contains('cornerRadius: 22'));
    expect(source, contains('density: ThemeDensity.compact'));
  });
}
