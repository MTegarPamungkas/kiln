import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:with_appwrite/extensions/l10n/locale_formatters.dart';

void main() {
  setUpAll(LocaleFormatters.initialize);

  group('LocaleFormatters', () {
    final indonesian = LocaleFormatters(locale: const Locale('id'));
    final english = LocaleFormatters(locale: const Locale('en'));

    test('defaults to Indonesian', () {
      expect(LocaleFormatters().languageCode, 'id');
    });

    test('formats dates per locale', () {
      final date = DateTime(2024, 1, 15);

      expect(indonesian.formatDate(date), '15 Januari 2024');
      expect(english.formatDate(date), '15 January 2024');
      expect(indonesian.formatDate(date, pattern: 'd/M/y'), '15/1/2024');
      expect(english.formatDate(date, pattern: 'd/M/y'), '15/1/2024');
    });

    test('formats medium dates and date-times', () {
      final value = DateTime(2024, 1, 15, 9, 30);

      expect(indonesian.formatMediumDate(value), contains('2024'));
      expect(english.formatMediumDate(value), contains('2024'));
      expect(indonesian.formatDateTime(value), contains('2024'));
      expect(english.formatDateTime(value), contains('09:30'));
    });

    test('formats numbers with locale separators', () {
      expect(indonesian.formatNumber(1234.5), '1.234,5');
      expect(english.formatNumber(1234.5), '1,234.5');
      expect(indonesian.formatNumber(1234.567, decimalDigits: 1), '1.234,6');
      expect(english.formatNumber(1234.567, decimalDigits: 2), '1,234.57');
    });

    test('formats percentages and compact numbers', () {
      expect(indonesian.formatPercent(0.12, decimalDigits: 0), '12%');
      expect(english.formatPercent(0.5), contains('50'));
      expect(indonesian.formatCompactNumber(1200), isNotEmpty);
      expect(english.formatCompactNumber(1200), contains('1'));
    });

    test('formats currency with the locale symbol', () {
      final rupiah = indonesian.formatCurrency(1250000, decimalDigits: 0);
      final dollars = english.formatCurrency(1234.5, currencyCode: 'USD');

      expect(rupiah, contains('Rp'));
      expect(rupiah, contains('1.250.000'));
      expect(dollars, contains(r'$'));
      expect(dollars, contains('1,234.50'));
    });
  });
}
