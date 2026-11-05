import 'package:kiln_core/kiln_core.dart';

import 'local_db_config.dart';

/// Web builds use IndexedDB through sembast_web.
Future<SupportInfo> probeLocalDatabaseSupport(LocalDbConfig config) async {
  return const SupportInfo.supported(
    details: <String, Object?>{'backend': 'sembast_web'},
  );
}
