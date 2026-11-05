import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/l10n/l10n_config.dart';

void main() {
  group('L10nConfig', () {
    test('exposes the prompt defaults', () {
      const config = L10nConfig.defaults;

      expect(config.supportedLocales, <Locale>[
        const Locale('id'),
        const Locale('en'),
      ]);
      expect(config.fallbackLocale, const Locale('id'));
      expect(config.resolvedFallback, const Locale('id'));
    });

    test('matches regional locales by language', () {
      const config = L10nConfig.defaults;

      expect(config.supports(const Locale('id', 'ID')), isTrue);
      expect(config.supports(const Locale('en', 'US')), isTrue);
      expect(config.supports(const Locale('fr')), isFalse);
      expect(config.canonical(const Locale('en', 'US')), const Locale('en'));
    });

    test('falls back for unsupported locales', () {
      const config = L10nConfig.defaults;

      expect(config.resolve(const Locale('id', 'ID')), const Locale('id'));
      expect(config.resolve(const Locale('en', 'GB')), const Locale('en'));
      expect(config.resolve(const Locale('fr')), const Locale('id'));
      expect(config.resolve(null), const Locale('id'));
    });

    test('uses the first supported locale when the fallback is missing', () {
      const config = L10nConfig(
        supportedLocales: <Locale>[Locale('en')],
        fallbackLocale: Locale('id'),
      );

      expect(config.resolvedFallback, const Locale('en'));
      expect(config.resolve(const Locale('fr')), const Locale('en'));
      expect(config.canonical(const Locale('id')), const Locale('en'));
    });

    test('keeps the configured fallback when no locale is supported', () {
      const config = L10nConfig(
        supportedLocales: <Locale>[],
        fallbackLocale: Locale('en'),
      );

      expect(config.supportedLocales, isEmpty);
      expect(config.resolvedFallback, const Locale('en'));
      expect(config.resolve(const Locale('id')), const Locale('en'));
    });
  });
}
