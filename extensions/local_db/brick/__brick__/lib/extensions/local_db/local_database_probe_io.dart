import 'package:flutter/services.dart' show MissingPluginException;
import 'package:kiln_core/kiln_core.dart';
import 'package:path_provider/path_provider.dart';

import 'local_db_config.dart';

/// Probes whether a writable application directory is available.
///
/// The database itself stays lazily opened; this only resolves the directory
/// and reports an informational state when the platform cannot provide one.
Future<SupportInfo> probeLocalDatabaseSupport(LocalDbConfig config) async {
  final explicitPath = config.path;
  if (explicitPath != null) {
    return SupportInfo.supported(
      details: <String, Object?>{'backend': 'sembast_io', 'path': explicitPath},
    );
  }
  try {
    final directory = await getApplicationDocumentsDirectory();
    return SupportInfo.supported(
      details: <String, Object?>{
        'backend': 'sembast_io',
        'directory': directory.path,
      },
    );
  } on MissingPluginException catch (error) {
    return SupportInfo.unsupported(
      SupportState.unsupportedPlatform,
      message: 'Local database paths are not available on this platform.',
      details: <String, Object?>{'error': '$error'},
    );
  } on UnsupportedError catch (error) {
    return SupportInfo.unsupported(
      SupportState.unsupportedPlatform,
      message: 'Local database paths are not available on this platform.',
      details: <String, Object?>{'error': '$error'},
    );
  } on Object catch (error) {
    return SupportInfo.unsupported(
      SupportState.unavailable,
      message: 'Local database storage is unavailable: $error',
      details: <String, Object?>{'error': '$error'},
    );
  }
}
