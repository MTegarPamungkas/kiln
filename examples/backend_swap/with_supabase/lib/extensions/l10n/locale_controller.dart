import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

import 'l10n_config.dart';
import 'locale_store.dart';

/// Owns the active locale choice for the application.
///
/// A `null` value means "follow the system locale". The controller is safe to
/// use without a [LocaleStore]; the choice then lasts for the current session.
final class LocaleController {
  LocaleController({
    this.config = L10nConfig.defaults,
    this.store,
    Locale? initialLocale,
  }) : _locale = ValueNotifier<Locale?>(_normalize(config, initialLocale));

  final L10nConfig config;

  /// Optional persistence. When `null`, [load] is a no-op and [setLocale]
  /// only updates the in-memory value.
  final LocaleStore? store;

  final ValueNotifier<Locale?> _locale;

  /// The live locale, suitable for `AppLocalizationsConfig.localeListenable`.
  ValueListenable<Locale?> get localeListenable => _locale;

  /// The notifier itself, for widgets that need to replace its listener.
  ValueNotifier<Locale?> get localeNotifier => _locale;

  /// `null` means the application follows the device locale.
  Locale? get locale => _locale.value;

  /// Restores the persisted choice. Failures are ignored because a missing
  /// preference must never block application startup.
  Future<void> load() async {
    final store = this.store;
    if (store == null) {
      return;
    }
    try {
      final stored = await store.readOrNull();
      if (stored != null && config.supports(stored)) {
        _locale.value = config.canonical(stored);
      }
    } on Object {
      // Preferences are best effort; keep following the system locale.
    }
  }

  /// Changes the locale and persists it.
  ///
  /// A `null` [next] follows the system locale. Unsupported locales throw an
  /// [ArgumentError] so programming mistakes surface in tests.
  Future<void> setLocale(Locale? next) async {
    final normalized = _normalize(config, next);
    _locale.value = normalized;
    await _persist(normalized);
  }

  /// Clears the explicit choice and follows the system locale again.
  Future<void> followSystem() => setLocale(null);

  /// Releases the notifier.
  void dispose() => _locale.dispose();

  Future<void> _persist(Locale? locale) async {
    final store = this.store;
    if (store == null) {
      return;
    }
    try {
      await store.save(locale);
    } on Object {
      // The selection still applies for this session.
    }
  }

  static Locale? _normalize(L10nConfig config, Locale? locale) {
    if (locale == null) {
      return null;
    }
    if (!config.supports(locale)) {
      throw ArgumentError.value(
        locale.toLanguageTag(),
        'locale',
        'Locale is not supported by L10nConfig',
      );
    }
    return config.canonical(locale);
  }
}
