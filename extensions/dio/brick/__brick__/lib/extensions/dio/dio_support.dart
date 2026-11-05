import 'package:kiln_core/kiln_core.dart';

import 'dio_config.dart';

/// Reports whether the configured HTTP client can be used.
final class DioSupport {
  const DioSupport({required this.config});

  final DioConfig config;

  SupportInfo get info {
    final problem = config.validate();
    if (problem != null) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: problem.message,
        details: <String, Object?>{'code': problem.code.value},
      );
    }
    final uri = Uri.tryParse(config.baseUrl);
    return SupportInfo.supported(
      details: <String, Object?>{
        'host': uri?.host,
        'api_key': config.hasApiKey,
        'connect_timeout_seconds': config.connectTimeout.inSeconds,
      },
    );
  }
}
