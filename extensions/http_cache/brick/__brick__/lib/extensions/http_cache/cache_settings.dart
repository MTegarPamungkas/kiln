/// Typed cache configuration.
final class HttpCacheSettings {
  const HttpCacheSettings({
    this.defaultTtl = const Duration(seconds: 60),
    this.maxEntries = 100,
    this.staleWhileRevalidate = true,
    this.cacheableStatusCodes = const <int>{
      200,
      203,
      204,
      206,
      300,
      301,
      308,
      404,
      410,
    },
  });

  static const defaults = HttpCacheSettings(
    defaultTtl: Duration(seconds: {{default_ttl_seconds}}),
    maxEntries: {{max_entries}},
    staleWhileRevalidate: {{stale_while_revalidate}},
  );

  final Duration defaultTtl;
  final int maxEntries;
  final bool staleWhileRevalidate;
  final Set<int> cacheableStatusCodes;
}
