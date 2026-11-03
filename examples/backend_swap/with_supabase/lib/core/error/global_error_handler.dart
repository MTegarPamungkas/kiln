import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

/// Routes Flutter and platform errors to Logger and CrashReporter when present.
void installGlobalErrorHandlers(Registry registry) {
  final logger = registry.readOrNull<AppLogger>();
  final crashReporter = registry.readOrNull<CrashReporter>();

  FlutterError.onError = (details) {
    logger?.error(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
    crashReporter?.captureError(
      details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger?.error(
      'Unhandled platform error',
      error: error,
      stackTrace: stackTrace,
    );
    crashReporter?.captureError(error, stackTrace: stackTrace);
    return true;
  };

  if (kDebugMode) {
    logger?.debug('Global error handlers installed');
  }
}
