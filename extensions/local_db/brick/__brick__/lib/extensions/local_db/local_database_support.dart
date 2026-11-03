import 'package:kiln_core/kiln_core.dart';

import 'local_database_probe.dart';
import 'local_db_config.dart';

typedef LocalDbSupportProbe = Future<SupportInfo> Function(
  LocalDbConfig config,
);

/// Caches the local database support probe.
final class LocalDatabaseSupport {
  LocalDatabaseSupport({required this.config, LocalDbSupportProbe? probe})
    : _probe = probe ?? probeLocalDatabaseSupport;

  final LocalDbConfig config;
  final LocalDbSupportProbe _probe;
  SupportInfo? _last;

  Future<SupportInfo> check() async {
    final last = _last;
    if (last != null) {
      return last;
    }
    SupportInfo info;
    try {
      info = await _probe(config);
    } on Object catch (error) {
      info = SupportInfo.unsupported(
        SupportState.unavailable,
        message: 'Local database support probe failed: $error',
        details: <String, Object?>{'error': '$error'},
      );
    }
    _last = info;
    return info;
  }

  void clear() => _last = null;
}
