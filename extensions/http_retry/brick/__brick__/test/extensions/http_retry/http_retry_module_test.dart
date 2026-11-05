import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/http_retry/http_retry_module.dart';
import 'package:{{app_name}}/extensions/http_retry/http_retry_support.dart';
import 'package:{{app_name}}/extensions/http_retry/retry_events.dart';
import 'package:{{app_name}}/extensions/http_retry/retry_middleware.dart';

void main() {
  test('module adds the retry middleware to the pipeline', () {
    final registry = GetItRegistry()
      ..registerSingleton<SlotRegistry>(SlotRegistry())
      ..registerSingleton<HttpPipeline>(HttpPipeline());

    const HttpRetryModule().register(registry);

    expect(registry.read<HttpPipeline>().middleware, hasLength(1));
    expect(registry.read<HttpRetrySupport>(), isA<HttpRetrySupport>());
  });

  test('module wires RetryEvents from the registry into the middleware', () {
    final events = RetryEvents(onRetry: (_) {}, onGiveUp: (_) {});
    final registry = GetItRegistry()
      ..registerSingleton<SlotRegistry>(SlotRegistry())
      ..registerSingleton<HttpPipeline>(HttpPipeline())
      ..registerSingleton<RetryEvents>(events);

    const HttpRetryModule().register(registry);

    final middleware = registry
        .read<HttpPipeline>()
        .middleware
        .whereType<RetryMiddleware>()
        .single;
    expect(middleware.events, same(events));
  });
}
