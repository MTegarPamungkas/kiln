import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/extensions/theme/brand_theme.dart';
import 'package:full_stack/extensions/theme/semantic_colors.dart';
import 'package:full_stack/extensions/theme/theme_config.dart';

const Key _swatchKey = Key('theme-swatches');

void main() {
  testWidgets('light and dark swatches match the golden', (tester) async {
    final brand = BrandTheme(ThemeConfig.defaults);

    await tester.pumpWidget(
      MaterialApp(
        theme: brand.light,
        home: const Center(
          child: RepaintBoundary(
            key: _swatchKey,
            child: _SwatchBoard(),
          ),
        ),
      ),
    );

    await expectGoldenWidget(
      tester,
      find.byKey(_swatchKey),
      'goldens/theme_swatches.png',
    );
  });
}

/// Renders fixed color blocks in both brightnesses.
///
/// The board contains no text or shadows so the golden stays deterministic
/// across platforms; only the scheme colors are captured.
class _SwatchBoard extends StatelessWidget {
  const _SwatchBoard();

  @override
  Widget build(BuildContext context) {
    final brand = BrandTheme(ThemeConfig.defaults);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _SwatchRow(theme: brand.light, brightness: Brightness.light),
        _SwatchRow(theme: brand.dark, brightness: Brightness.dark),
      ],
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.theme, required this.brightness});

  final ThemeData theme;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final semantic =
        theme.extension<SemanticColors>() ??
        SemanticColors.forBrightness(brightness);
    final swatches = <Color>[
      colors.primary,
      colors.secondary,
      colors.tertiary,
      colors.error,
      colors.surface,
      semantic.success,
      semantic.warning,
      semantic.info,
    ];

    return SizedBox(
      width: 360,
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final color in swatches)
            Expanded(child: ColoredBox(color: color)),
        ],
      ),
    );
  }
}
