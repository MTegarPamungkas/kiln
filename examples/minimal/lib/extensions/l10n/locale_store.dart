import 'dart:ui' show Locale;

import 'package:kiln_core/kiln_core.dart';

/// Persists the user's locale choice through [Storage].
final class LocaleStore {
  const LocaleStore(this.storage, {this.key = defaultKey});

  /// Storage key used by the extension.
  static const String defaultKey = 'kiln.l10n.locale';

  final Storage storage;
  final String key;

  static final RegExp _tagPattern = RegExp(
    r'^[A-Za-z]{2,3}([_-][A-Za-z0-9]{2,8})*$',
  );

  /// Reads the stored locale, or `null` when nothing valid is stored.
  Future<Locale?> readOrNull() async {
    final raw = await storage.read(key);
    return _decode(raw);
  }

  /// Stores [locale]. A `null` locale follows the system and clears the key.
  Future<void> save(Locale? locale) async {
    if (locale == null) {
      await storage.delete(key);
      return;
    }
    await storage.write(key, locale.toLanguageTag());
  }

  /// Removes the stored choice.
  Future<void> clear() => storage.delete(key);

  Locale? _decode(String? raw) {
    final tag = raw?.trim();
    if (tag == null || tag.isEmpty || !_tagPattern.hasMatch(tag)) {
      return null;
    }
    final parts = tag.split(RegExp('[-_]'));
    final language = parts.first.toLowerCase();
    String? script;
    String? country;
    for (final part in parts.skip(1)) {
      if (part.length == 4 && RegExp(r'^[A-Za-z]+$').hasMatch(part)) {
        script = _capitalize(part);
      } else if (part.length == 2 || part.length == 3) {
        country = part.toUpperCase();
      }
    }
    return Locale.fromSubtags(
      languageCode: language,
      scriptCode: script,
      countryCode: country,
    );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }
}
