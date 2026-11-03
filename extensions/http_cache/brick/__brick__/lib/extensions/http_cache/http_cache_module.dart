import 'package:kiln_core/kiln_core.dart';

import 'cache_interceptor.dart';
import 'cache_settings.dart';
import 'http_cache_support.dart';
import 'memory_http_cache.dart';
import 'storage_http_cache.dart';

/// Registers the HTTP cache and its middleware.
final class HttpCacheModule extends KilnModule {
  const HttpCacheModule();

  @override
  String get id => 'http_cache';

  @override
  Set<String> get provides => const <String>{'http_cache'};

  @override
  Set<String> get requires => const <String>{'http_client', 'http_pipeline'};

  @override
  Set<String> get optionalRequires => const <String>{'storage'};

  @override
  void register(Registry registry) {
    final clock = registry.readOrNull<Clock>() ?? const SystemClock();
    final storage = registry.readOrNull<Storage>();
    final HttpCache cache = storage == null
        ? MemoryHttpCache(settings: HttpCacheSettings.defaults, clock: clock)
        : StorageHttpCache(
            storage: storage,
            settings: HttpCacheSettings.defaults,
            clock: clock,
          );

    registry.registerSingleton<HttpCache>(cache);
    registry.registerSingleton<HttpCacheSupport>(
      HttpCacheSupport(settings: HttpCacheSettings.defaults, storage: storage),
    );
    registry.read<HttpPipeline>().use(
      CacheInterceptor(
        cache: cache,
        settings: HttpCacheSettings.defaults,
        clock: clock,
      ),
      priority: 30,
    );
  }

  @override
  SupportInfo support(Registry registry) {
    return registry.read<HttpCacheSupport>().info;
  }
}
