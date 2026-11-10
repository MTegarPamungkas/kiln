import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/l10n/generated/app_localizations.dart';

void main() {
  test('generated localizations load ARB messages per locale', () async {
    final indonesian = await AppLocalizations.delegate.load(const Locale('id'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));

    expect(indonesian.readyTitle, 'Aplikasi siap');
    expect(english.readyTitle, 'App ready');
    expect(indonesian.languageName, 'Bahasa Indonesia');
    expect(english.languageName, 'English');
  });

  test('ARB placeholders and plurals are generated', () {
    final english = lookupAppLocalizations(const Locale('en'));
    final indonesian = lookupAppLocalizations(const Locale('id'));

    expect(english.helloName('Tegar'), 'Hello, Tegar!');
    expect(indonesian.helloName('Tegar'), 'Halo, Tegar!');
    expect(english.itemsCount(0), 'No items');
    expect(english.itemsCount(1), '1 item');
    expect(english.itemsCount(3), '3 items');
    expect(indonesian.itemsCount(0), 'Tidak ada item');
    expect(indonesian.itemsCount(3), '3 item');
  });

  test('supported locales match the generated ARB files', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      containsAll(<String>['id', 'en']),
    );
    expect(
      AppLocalizations.localizationsDelegates,
      contains(AppLocalizations.delegate),
    );
  });
}
