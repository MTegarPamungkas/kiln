import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/l10n/locale_resolution.dart';

void main() {
  const supported = <Locale>[Locale('id'), Locale('en')];

  Locale resolve(Locale? device) {
    return LocaleResolution.resolve(
      device,
      supported: supported,
      fallback: const Locale('id'),
    );
  }

  group('LocaleResolution', () {
    test('maps id_ID to id', () {
      expect(resolve(const Locale('id', 'ID')), const Locale('id'));
    });

    test('maps regional English to en', () {
      expect(resolve(const Locale('en', 'US')), const Locale('en'));
      expect(resolve(const Locale('en', 'GB')), const Locale('en'));
    });

    test('matches exact tags before language-only entries', () {
      const regional = <Locale>[Locale('id'), Locale('pt', 'BR')];

      expect(
        LocaleResolution.resolve(
          const Locale('pt', 'BR'),
          supported: regional,
          fallback: const Locale('id'),
        ),
        const Locale('pt', 'BR'),
      );
    });

    test('uses the fallback for unsupported and missing locales', () {
      expect(resolve(const Locale('fr', 'FR')), const Locale('id'));
      expect(resolve(null), const Locale('id'));
    });

    test('uses the fallback when nothing is supported', () {
      expect(
        LocaleResolution.resolve(
          const Locale('en'),
          supported: const <Locale>[],
          fallback: const Locale('id'),
        ),
        const Locale('id'),
      );
    });

    test('reports language support', () {
      expect(LocaleResolution.supports(const Locale('id'), const Locale('id')), isTrue);
      expect(
        LocaleResolution.supports(const Locale('en'), const Locale('en', 'US')),
        isTrue,
      );
      expect(
        LocaleResolution.supports(const Locale('id'), const Locale('en')),
        isFalse,
      );
    });
  });
}
