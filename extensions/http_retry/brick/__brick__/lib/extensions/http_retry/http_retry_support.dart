import 'package:kiln_core/kiln_core.dart';

import 'retry_settings.dart';

/// Reports whether the retry policy settings are usable.
final class HttpRetrySupport {
  const HttpRetrySupport({required this.settings});

  final HttpRetrySettings settings;

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
        'max_attempts': settings.maxAttempts,
        'initial_delay_ms': settings.initialDelay.inMilliseconds,
        'max_delay_ms': settings.maxDelay.inMilliseconds,
        'jitter': settings.jitter,
      },
    );
  }
}
