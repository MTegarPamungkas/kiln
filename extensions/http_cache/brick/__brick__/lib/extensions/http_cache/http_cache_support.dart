import 'package:kiln_core/kiln_core.dart';

import 'cache_settings.dart';

/// Reports cache settings and whether it uses persistent storage.
final class HttpCacheSupport {
  const HttpCacheSupport({required this.settings, this.storage});

  final HttpCacheSettings settings;
  final Storage? storage;

  SupportInfo get info {
    final problem = settings.validate();
    if (problem != null) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: problem.message,
        details: <String, Object?>{'code': problem.code.value},
      );
    }
    return SupportInfo.supported(
      details: <String, Object?>{
        'backend': storage == null ? 'memory' : 'storage',
        'max_entries': settings.maxEntries,
        'ttl_seconds': settings.defaultTtl.inSeconds,
        'stale_while_revalidate': settings.staleWhileRevalidate,
      },
    );
  }
}
