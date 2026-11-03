import 'package:kiln_core/kiln_core.dart';

import 'retry_budget.dart';
import 'retry_middleware.dart';
import 'retry_settings.dart';

/// Adds the retry middleware to the registered HTTP pipeline.
final class HttpRetryModule extends KilnModule {
  const HttpRetryModule();

  @override
  String get id => 'http_retry';

  @override
  Set<String> get requires => const <String>{
    'http_client',
    'http_pipeline',
  };

  @override
  void register(Registry registry) {
    final pipeline = registry.read<HttpPipeline>();
    pipeline.use(
      RetryMiddleware(
        settings: HttpRetrySettings.defaults,
        budget: RetryBudget(clock: registry.readOrNull<Clock>()),
      ),
      priority: 20,
    );
  }
}
