import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/l10n/l10n_config.dart';
import 'package:full_stack/extensions/l10n/l10n_support.dart';

void main() {
  test('reports locales, fallback, and memory fallback', () {
    const support = L10nSupport(config: L10nConfig.defaults);

    final info = support.info;

    expect(info.isSupported, isTrue);
    expect(info.details['fallback'], 'id');
    expect(info.details['storage'], 'memory');
    expect(info.details['locales'], isA<List<Object?>>());
  });

  test('reports persistent locale storage', () {
    const support = L10nSupport(config: L10nConfig.defaults, persisted: true);

    expect(support.info.details['storage'], 'storage');
  });

  test('reports an empty locale set as not configured', () {
    const support = L10nSupport(
      config: L10nConfig(
        supportedLocales: <Locale>[],
        fallbackLocale: Locale('id'),
      ),
    );

    expect(support.info.state, SupportState.notConfigured);
  });
}
