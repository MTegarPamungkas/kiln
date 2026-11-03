import 'package:kiln_core/kiln_core.dart';

import 'http_retry_support.dart';
import 'retry_budget.dart';
import 'retry_middleware.dart';
import 'retry_settings.dart';

/// Adds the retry middleware to the registered HTTP pipeline.
final class HttpRetryModule extends KilnModule {
  const HttpRetryModule();

  @override
  String get id => 'http_retry';

  @override
  Set<String> get requires => const <String>{'http_client', 'http_pipeline'};

  @override
  void register(Registry registry) {
    const settings = HttpRetrySettings.defaults;
    final pipeline = registry.read<HttpPipeline>();
    pipeline.use(
      RetryMiddleware(
        settings: settings,
        budget: RetryBudget(clock: registry.readOrNull<Clock>()),
      ),
      priority: 20,
    );
    registry.registerSingleton<HttpRetrySupport>(
      const HttpRetrySupport(settings: settings),
    );
  }

  @override
  SupportInfo support(Registry registry) {
    return registry.read<HttpRetrySupport>().info;
  }
}
