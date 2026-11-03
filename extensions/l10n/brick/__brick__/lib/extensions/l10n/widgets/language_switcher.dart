import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../l10n_config.dart';
import '../locale_controller.dart';

/// Presentation used by [LanguageSwitcher].
enum LanguageSwitcherStyle { dropdown, segmented }

/// Lets the user pick the application language.
///
/// The list comes from [L10nConfig.supportedLocales]. Selecting "follow system"
/// clears the explicit choice so the device locale applies again.
final class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({
    required this.controller,
    this.config = L10nConfig.defaults,
    this.style = LanguageSwitcherStyle.dropdown,
    super.key,
  });

  final LocaleController controller;
  final L10nConfig config;

  final LanguageSwitcherStyle style;

  static const String _systemTag = '__system__';

  static const Map<String, String> _languageNames = <String, String>{
    'ar': 'العربية',
    'de': 'Deutsch',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'hi': 'हिन्दी',
    'id': 'Bahasa Indonesia',
    'it': 'Italiano',
    'ja': '日本語',
    'ko': '한국어',
    'ms': 'Bahasa Melayu',
    'nl': 'Nederlands',
    'pl': 'Polski',
    'pt': 'Português',
    'ru': 'Русский',
    'sv': 'Svenska',
    'th': 'ไทย',
    'tr': 'Türkçe',
    'vi': 'Tiếng Việt',
    'zh': '中文',
  };

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context);
    return ValueListenableBuilder<Locale?>(
      valueListenable: controller.localeListenable,
      builder: (context, activeLocale, _) {
        final selected = _selectedTag(activeLocale);
        return switch (style) {
          LanguageSwitcherStyle.dropdown => _buildDropdown(copy, selected),
          LanguageSwitcherStyle.segmented => _buildSegmented(copy, selected),
        };
      },
    );
  }

  Widget _buildDropdown(AppLocalizations copy, String selected) {
    return Tooltip(
      message: copy.languageLabel,
      child: DropdownButton<String>(
        key: const Key('kiln-language-switcher'),
        value: selected,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: <DropdownMenuItem<String>>[
          DropdownMenuItem<String>(
            value: _systemTag,
            child: Text(copy.languageFollowSystem),
          ),
          for (final locale in _locales)
            DropdownMenuItem<String>(
              value: _tag(locale),
              child: Text(_languageName(locale)),
            ),
        ],
        onChanged: (value) => unawaited(_select(value)),
      ),
    );
  }

  Widget _buildSegmented(AppLocalizations copy, String selected) {
    return Tooltip(
      message: copy.languageLabel,
      child: SegmentedButton<String>(
        key: const Key('kiln-language-switcher-segmented'),
        segments: <ButtonSegment<String>>[
          ButtonSegment<String>(
            value: _systemTag,
            label: Text(copy.languageFollowSystem),
            icon: const Icon(Icons.settings_outlined),
          ),
          for (final locale in _locales)
            ButtonSegment<String>(
              value: _tag(locale),
              label: Text(_languageName(locale)),
            ),
        ],
        selected: <String>{selected},
        onSelectionChanged: (selection) {
          if (selection.isEmpty) {
            return;
          }
          unawaited(_select(selection.first));
        },
      ),
    );
  }

  List<Locale> get _locales {
    final seen = <String>{};
    return <Locale>[
      for (final locale in config.supportedLocales)
        if (seen.add(_tag(locale))) locale,
    ];
  }

  String _selectedTag(Locale? active) {
    if (active == null) {
      return _systemTag;
    }
    final tag = _tag(active);
    for (final locale in _locales) {
      if (_tag(locale) == tag) {
        return tag;
      }
    }
    return _systemTag;
  }

  Future<void> _select(String? tag) async {
    if (tag == null) {
      return;
    }
    if (tag == _systemTag) {
      await controller.followSystem();
      return;
    }
    for (final locale in _locales) {
      if (_tag(locale) == tag) {
        await controller.setLocale(locale);
        return;
      }
    }
  }

  static String _tag(Locale locale) {
    final tag = locale.toLanguageTag();
    return tag.isEmpty ? locale.languageCode.toLowerCase() : tag;
  }

  static String _languageName(Locale locale) {
    final name = _languageNames[locale.languageCode.toLowerCase()];
    if (name != null) {
      return name;
    }
    final tag = locale.toLanguageTag();
    return tag.isEmpty ? locale.languageCode : tag;
  }
}
