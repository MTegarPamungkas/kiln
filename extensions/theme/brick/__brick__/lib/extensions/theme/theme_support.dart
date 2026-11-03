import 'package:kiln_core/kiln_core.dart';

import 'theme_config.dart';

/// Reports the active theme configuration and preference backend.
final class ThemeSupport {
  const ThemeSupport({required this.config, this.persisted = false});

  final ThemeConfig config;
  final bool persisted;

  SupportInfo get info {
    final problem = config.validate();
    if (problem != null) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: problem.message,
        details: <String, Object?>{'code': problem.code.value},
      );
    }
    return SupportInfo.supported(
      details: <String, Object?>{
        'seed': config.seedColor.toARGB32().toRadixString(16),
        'font': config.fontFamily,
        'density': config.density.name,
        'storage': persisted ? 'storage' : 'memory',
      },
    );
  }
}
