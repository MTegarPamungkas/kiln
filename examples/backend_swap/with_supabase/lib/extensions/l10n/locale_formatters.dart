import 'dart:ui' show Locale;

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Locale-aware date, number, and currency formatting.
///
/// Date symbols must be initialized before formatting dates. The l10n module
/// does this during startup; unit tests can call [initialize] or intl's
/// `initializeDateFormatting`.
final class LocaleFormatters {
  LocaleFormatters({Locale? locale}) : locale = locale ?? const Locale('id');

  final Locale locale;

  String get languageCode => locale.languageCode;

  /// Initializes intl date symbols for every bundled locale.
  static Future<void> initialize() => initializeDateFormatting();

  /// Formats [value] using [pattern] (default `d MMMM y`).
  String formatDate(DateTime value, {String pattern = 'd MMMM y'}) {
    return DateFormat(pattern, languageCode).format(value);
  }

  /// Formats [value] using the locale's medium date pattern.
  String formatMediumDate(DateTime value) {
    return DateFormat.yMMMd(languageCode).format(value);
  }

  /// Formats [value] using the locale's medium date and time pattern.
  String formatDateTime(DateTime value) {
    return DateFormat.yMMMd(languageCode).add_Hm().format(value);
  }

  /// Formats a decimal number, optionally with a fixed number of decimals.
  String formatNumber(num value, {int? decimalDigits}) {
    final format = NumberFormat.decimalPattern(languageCode);
    if (decimalDigits != null) {
      format
        ..minimumFractionDigits = decimalDigits
        ..maximumFractionDigits = decimalDigits;
    }
    return format.format(value);
  }

  /// Formats a percentage, for example `12%`.
  String formatPercent(num ratio, {int? decimalDigits}) {
    final format = NumberFormat.percentPattern(languageCode);
    if (decimalDigits != null) {
      format
        ..minimumFractionDigits = decimalDigits
        ..maximumFractionDigits = decimalDigits;
    }
    return format.format(ratio);
  }

  /// Formats [value] as a compact number such as `1,2 rb` or `1.2K`.
  String formatCompactNumber(num value) {
    return NumberFormat.compact(locale: languageCode).format(value);
  }

  /// Formats [value] as currency using the locale's symbol for [currencyCode].
  String formatCurrency(
    num value, {
    String currencyCode = 'IDR',
    int? decimalDigits,
  }) {
    final symbol = NumberFormat.simpleCurrency(
      locale: languageCode,
      name: currencyCode,
    ).currencySymbol;
    return NumberFormat.currency(
      locale: languageCode,
      name: currencyCode,
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(value);
  }
}
