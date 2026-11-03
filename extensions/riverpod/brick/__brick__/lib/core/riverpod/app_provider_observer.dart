import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiln_core/kiln_core.dart';

/// Logs provider updates and failures through the application logger.
final class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver({required this.logger});

  final AppLogger logger;

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    logger.debug('provider updated: ${context.provider.runtimeType}');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    logger.error(
      'provider failed: ${context.provider.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
