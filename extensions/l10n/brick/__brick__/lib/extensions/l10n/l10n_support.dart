import 'package:kiln_core/kiln_core.dart';

import 'l10n_config.dart';

/// Reports supported locales, fallback, and preference storage.
final class L10nSupport {
  const L10nSupport({required this.config, this.persisted = false});

  final L10nConfig config;
  final bool persisted;

  SupportInfo get info {
    if (config.supportedLocales.isEmpty) {
      return const SupportInfo.unsupported(
        SupportState.notConfigured,
        message: 'No locales are configured for this app.',
      );
    }
    return SupportInfo.supported(
      details: <String, Object?>{
        'locales': <String>[
          for (final locale in config.supportedLocales) locale.toLanguageTag(),
        ],
        'fallback': config.resolvedFallback.toLanguageTag(),
        'storage': persisted ? 'storage' : 'memory',
      },
    );
  }
}
